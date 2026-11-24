import os
import pwd
import threading

from PySide6.QtCore import Property, QObject, QProcess, QTimer, Signal, Slot

import desktops
import plan
import userconf

HERE = os.path.dirname(os.path.abspath(__file__))
HELPER = "/usr/lib/weka/weka-helper"
STEPS = ["snapshot", "install", "login", "remove", "verify", "config"]


class Backend(QObject):
    planReady = Signal("QVariantMap")
    planFailed = Signal(str)
    stepChanged = Signal()
    logAdded = Signal(str)
    finished = Signal(bool, str)
    _planDone = Signal("QVariantMap", str)

    def __init__(self, dry_run=False):
        super().__init__()
        self._dry = dry_run
        self._home = pwd.getpwuid(os.getuid()).pw_dir
        self._sys = plan.Sys()
        self._current = plan.detect(self._sys, self._home)
        self._session = self._running()
        self._step = ""
        self._keep = {}
        self._default = ""
        self._proc = None
        self._gen = 0
        self._planDone.connect(self._onPlan)

    def _running(self):
        names = os.environ.get("XDG_CURRENT_DESKTOP", "").lower().split(":")
        names += [os.environ.get("DESKTOP_SESSION", "").lower().rsplit("/", 1)[-1]]
        for d in desktops.DESKTOPS:
            if d["id"] in names or d["session"] in names or d["name"].lower() in names:
                return d["id"]
        if "kde" in names:
            return "plasma"
        return ""

    @Property(bool, constant=True)
    def dryRun(self):
        return self._dry

    @Property("QVariantList", constant=True)
    def catalogue(self):
        return desktops.catalogue()

    @Property("QVariantMap", constant=True)
    def current(self):
        return {k: v or "" for k, v in self._current.items()}

    @Property(str, constant=True)
    def running(self):
        return self._session

    @Property(str, constant=True)
    def currentDefault(self):
        dm = self._sys.current_dm()
        for did in self._current:
            if desktops.find(did)["dm"] == dm:
                return did
        return next(iter(self._current), "")

    @Property(str, notify=stepChanged)
    def step(self):
        return self._step

    @Property("QVariantList", constant=True)
    def steps(self):
        return STEPS

    def _setStep(self, s):
        self._step = s
        self.stepChanged.emit()

    @Slot("QVariantMap", str, bool)
    def preview(self, keep, default, apps):
        keep = {k: (v or None) for k, v in keep.items()}
        try:
            plan.validate(keep, default)
        except ValueError as e:
            self.planFailed.emit(str(e))
            return
        self._gen += 1
        gen = self._gen

        def work():
            try:
                p = plan.build(self._sys, self._current, keep, default, apps)
                p["keep"] = {k: v or "" for k, v in p["keep"].items()}
                p["kept_apps"] = [{"pkg": k, "apps": v} for k, v in p["kept_apps"].items()]
                p["gen"] = gen
                self._planDone.emit(p, "")
            except Exception as e:
                self._planDone.emit({"gen": gen}, str(e))

        threading.Thread(target=work, daemon=True).start()

    def _onPlan(self, p, err):
        if p.get("gen") != self._gen:
            return
        if err:
            self.planFailed.emit(err)
        else:
            self.planReady.emit(p)

    def _args(self, keep, default, apps):
        args = []
        for k, v in keep.items():
            args += ["--keep", f"{k}:{v}" if v else k]
        args += ["--default", default]
        if apps:
            args.append("--remove-apps")
        return args

    @Slot("QVariantMap", str, bool)
    def apply(self, keep, default, apps):
        keep = {k: (v or None) for k, v in keep.items()}
        self._keep, self._default = keep, default
        if self._dry:
            self._fake()
            return
        self._proc = QProcess(self)
        self._proc.setProcessChannelMode(QProcess.MergedChannels)
        self._proc.readyReadStandardOutput.connect(self._read)
        self._proc.finished.connect(self._done)
        self._buf = ""
        self._error = ""
        self._ok = False
        self._proc.start("pkexec", [HELPER, "apply", *self._args(keep, default, apps)])

    def _line(self, line):
        kind, _, text = line.partition("\t")
        if kind == "step":
            self._setStep(text)
        elif kind == "cmd":
            self.logAdded.emit("$ " + text)
        elif kind == "log":
            self.logAdded.emit(text)
        elif kind == "error":
            self._error = text
            self.logAdded.emit("error: " + text)
        elif kind == "done":
            self._ok = True
        elif line.strip():
            self.logAdded.emit(line)

    def _read(self):
        self._buf += bytes(self._proc.readAllStandardOutput()).decode(errors="replace")
        *lines, self._buf = self._buf.split("\n")
        for line in lines:
            self._line(line)

    def _done(self, code, _status):
        if self._buf:
            self._line(self._buf)
            self._buf = ""
        if code in (126, 127) and not self._ok:
            self.finished.emit(False, "Authentication was cancelled. Nothing changed.")
            return
        if not self._ok:
            self.finished.emit(False, self._error or f"Something went wrong (code {code}).")
            return
        self._config()

    def _config(self):
        self._setStep("config")
        try:
            userconf.apply_all(self._home, self._keep, self.logAdded.emit)
        except Exception as e:
            self.logAdded.emit(f"error: {e}")
            self.finished.emit(True, "Desktops changed, but your config could not be updated fully. Check the log.")
            return
        self.finished.emit(True, "")

    def _fake(self):
        seq = []
        for s in STEPS[:-1]:
            seq += [("step", s), ("cmd", f"pretend {s}"), ("log", "ok")]
        seq.append(("done", self._default))
        self._ok = False
        self._error = ""

        def tick():
            if not seq:
                self._setStep("config")
                self.logAdded.emit("dry run: skipping config writes")
                self.finished.emit(True, "")
                return
            k, t = seq.pop(0)
            self._line(f"{k}\t{t}")
            QTimer.singleShot(250, tick)

        QTimer.singleShot(250, tick)

    @Slot()
    def reboot(self):
        if self._dry:
            self.logAdded.emit("dry run: would reboot")
            return
        QProcess.startDetached("systemctl", ["reboot"])

    @Slot()
    def logout(self):
        if self._dry:
            self.logAdded.emit("dry run: would log out")
            return
        sid = os.environ.get("XDG_SESSION_ID")
        if sid:
            QProcess.startDetached("loginctl", ["terminate-session", sid])
