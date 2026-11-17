import os, re, glob

root = r"D:\deepseekHarmas\PomodoroFocus"
def read(p):
    return open(p, encoding="utf-8").read()

settings_src = read(os.path.join(root, r"PomodoroFocus\Models\Phase.swift"))
fields = set(re.findall(r'^\s{4}var (\w+):', settings_src, re.M))

appmodel = read(os.path.join(root, r"PomodoroFocus\Core\AppModel.swift")) + \
           read(os.path.join(root, r"PomodoroFocus\Core\AppModel+Stats.swift"))
methods = set(re.findall(r'(?:func|var) (\w+)', appmodel))

views = [f for f in glob.glob(root + r"\PomodoroFocus\**\*.swift", recursive=True)
         if r"\Views" in f or "BlockApps" in f or "FocusView" in f]
used_settings, used_members = set(), set()
for f in views:
    src = read(f)
    used_settings |= set(re.findall(r'model\.settings\.(\w+)', src))
    used_members |= set(re.findall(r'model\.(\w+)', src))
used_members -= used_settings

print("AppSettings 字段:", sorted(fields))
bad = sorted(used_settings - fields)
print("views 用了但 AppSettings 没有的字段:", bad if bad else "none")

known_extra = {"settings"}
bad2 = sorted(used_members - methods - known_extra)
print("views 用了但 AppModel 没有的成员:", bad2 if bad2 else "none")