import os, re, glob

root = r"D:\deepseekHarmas\PomodoroFocus"
files = glob.glob(root + r"\**\*.swift", recursive=True)
print("swift files:", len(files))
for f in sorted(files):
    print("  ", os.path.relpath(f, root))

bad = []
for f in files:
    src = open(f, encoding="utf-8").read()
    s = re.sub(r'"(?:[^"\\]|\\.)*"', '""', src)
    s = re.sub(r'//[^\n]*', '', s)
    s = re.sub(r'/\*.*?\*/', '', s, flags=re.S)
    for op, cl in (("{", "}"), ("(", ")"), ("[", "]")):
        if s.count(op) != s.count(cl):
            bad.append((os.path.relpath(f, root), op, s.count(op), s.count(cl)))
print("unbalanced:", bad if bad else "none")

decls = {}
for f in files:
    src = open(f, encoding="utf-8").read()
    for m in re.finditer(r'^(?:[\t ]*@\w+[\t ]+)*(?:public |private |internal |final )*(struct|class|enum|extension)\s+([A-Za-z_][A-Za-z0-9_]*)', src, re.M):
        decls.setdefault(m.group(2), []).append(os.path.relpath(f, root))

expected = """Theme AppBackground GlassCard TapScale CircleIconButton ChipView SectionTitle PrimaryButton ToastView
StepButton StepperRow ToggleRow StatTile Phase FocusTask SessionRecord AppSettings NoiseKind NoiseEngine SoundPlayer
Haptics Notifications SessionAttributes AppModel DayStat TaskRank ScreenTimeManager BlockAppsView FamilyPickerSheet
LiveActivityController MainTab RootView TabBar FocusView TimerRing GoalRing TasksView TaskRow ProgressDots TaskEditorView
StatsView SettingsView PomodoroFocusApp SessionLiveActivityWidget LockScreenSessionView PomodoroWidgetBundle Color""".split()
missing = [e for e in expected if e not in decls]
print("missing decls:", missing if missing else "none")
dupes = {k: v for k, v in decls.items() if len(v) > 1 and k in expected}
print("multi-declared:", dupes if dupes else "none")

# rough check: capitalised identifiers used but never declared anywhere (filter known Apple types)
apple = set("""SwiftUI UIKit Foundation Combine Charts ActivityKit WidgetKit FamilyControls ManagedSettings UserNotifications AVFoundation
Date UUID Int String Double Bool CGFloat Void Set Array Color Text Image Button VStack HStack ZStack ScrollView LazyVStack ForEach
Spacer Divider Circle Capsule RoundedRectangle GeometryReader DragGesture Toggle Slider Stepper NavigationStack ScrollView
TextField Binding State StateObject EnvironmentObject Environment Published ObservableObject View App Scene Widget WidgetBundle
WidgetConfiguration ActivityAttributes Activity ActivityContent ActivityAuthorizationInfo DynamicIsland DynamicIslandExpandedRegion
ActivityConfiguration ActivityViewContext FamilyActivityPicker FamilyActivitySelection AuthorizationCenter ManagedSettingsStore
ShieldSettings ApplicationToken WebDomainToken ActivityCategoryToken UNMutableNotificationContent UNNotificationContent
UNTimeIntervalNotificationTrigger UNNotificationRequest UNUserNotificationCenter AVAudioEngine AVAudioPlayerNode AVAudioPCMBuffer
AVAudioFormat AVAudioSession UIImpactFeedbackGenerator UINotificationFeedbackGenerator UIApplication Timer RunLoop Task
Calendar DateFormatter Locale JSONEncoder JSONDecoder UserDefaults Bundle Foundation Character ClosedRange Timer
Chart BarMark AxisMarks AxisGridLine AxisValueLabel AnyShapeStyle ProgressView LinearGradient RadialGradient UnitPoint
Font Animation EdgeInsets AxisMarkValues AxisMarkPosition ButtonStyle ToggleStyle Slider ProgressViewStyle
UUID NumberFormatter NotificationCenter CGFloat NSSet Data Error TimeInterval Task MainActor Never AnyView Path Shape Style
PropertyWrapper Codable Hashable Equatable Identifiable CaseIterable Encodable Decodable Sendable""".split())

used = {}
for f in files:
    src = open(f, encoding="utf-8").read()
    s = re.sub(r'"(?:[^"\\]|\\.)*"', '""', src)
    s = re.sub(r'//[^\n]*', '', s)
    for m in re.finditer(r'\b([A-Z][A-Za-z0-9_]{2,})\b', s):
        used.setdefault(m.group(1), set()).add(os.path.relpath(f, root))
unknown = {k: sorted(v) for k, v in used.items() if k not in decls and k not in apple}
print("unknown capitalised identifiers:", len(unknown))
for k, v in sorted(unknown.items()):
    print("   ", k, v)
