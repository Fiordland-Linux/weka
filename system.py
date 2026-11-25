import glob
import os

MIN_KB = 4 * 1024 * 1024
SOFTWARE_ENV = {"LIBGL_ALWAYS_SOFTWARE": None, "GALLIUM_DRIVER": "llvmpipe", "QT_QUICK_BACKEND": "software",
                "QMLSCENE_DEVICE": "softwarecontext"}


def mem_total_kb(text):
    for line in text.splitlines():
        if line.startswith("MemTotal:"):
            parts = line.split()
            if len(parts) >= 2 and parts[1].isdigit():
                return int(parts[1])
    return None


def read_meminfo():
    try:
        with open("/proc/meminfo") as f:
            return f.read()
    except OSError:
        return ""


def render_nodes():
    return glob.glob("/dev/dri/renderD*")


def flag(env, name):
    value = env.get(name)
    return None if value not in ("0", "1") else value == "1"


def low_end(env=None, meminfo=None, nodes=None):
    env = os.environ if env is None else env
    forced = flag(env, "WEKA_LOW_END")
    if forced is not None:
        return forced
    for key, want in SOFTWARE_ENV.items():
        value = env.get(key)
        if value and (want is None and value != "0" or value == want):
            return True
    kb = mem_total_kb(read_meminfo() if meminfo is None else meminfo)
    if kb is not None and kb < MIN_KB:
        return True
    return not (render_nodes() if nodes is None else nodes)


def reduced_motion(env=None, low=None):
    env = os.environ if env is None else env
    forced = flag(env, "WEKA_REDUCE_MOTION")
    if forced is not None:
        return forced
    return low_end(env) if low is None else low
