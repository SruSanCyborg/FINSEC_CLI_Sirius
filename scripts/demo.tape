# The README demo, recorded live. Re-record with:  pnpm demo:record
#
# Same walk as the original: the shell and a streaming /scan over a real project,
# inline /triage, then guard and revenue on generated data, then the scan, triage,
# reconcile, baseline, badge and signed-report beats in a repo.

Output media/sirus-demo.mp4

Require sirus

Set Shell zsh
Set FontFamily "Menlo"
Set FontSize 17
Set Width 1180
Set Height 980
Set Padding 22
Set WindowBar Colorful
Set WindowBarSize 36
Set BorderRadius 10
Set Margin 0
Set Theme { "name": "sirus", "background": "#1e1e1e", "foreground": "#e6e6e6", "cursor": "#e6e6e6", "selection": "#3a3d41", "black": "#1e1e1e", "brightBlack": "#6e7681", "red": "#ff5c6c", "brightRed": "#ff7b88", "green": "#04b575", "brightGreen": "#3fd09a", "yellow": "#f5b041", "brightYellow": "#ffd27a", "blue": "#5ac8fa", "brightBlue": "#8fd8ff", "magenta": "#7c3aed", "brightMagenta": "#a78bfa", "cyan": "#5ac8fa", "brightCyan": "#8fd8ff", "white": "#e6e6e6", "brightWhite": "#ffffff" }
Set TypingSpeed 45ms
Set Framerate 30
Set PlaybackSpeed 1

Hide
Type "export PATH=$HOME/sirus-demo/.bin:$PATH COLORTERM=truecolor && unset RPROMPT && PROMPT='%F{245}%1~%f %% ' && cd ~/sirus-demo/finsec-gui && clear"
Enter
Sleep 1s
Show

# 1 · the shell, the command palette, a streaming scan, inline triage
Sleep 800ms
Type "sirus"
Sleep 400ms
Enter
Sleep 3s
Type "/"
Sleep 3s
Backspace
Sleep 500ms
Type "/scan"
Sleep 600ms
Enter
Sleep 40s
Type "/triage"
Sleep 500ms
Enter
Sleep 2s
Type "a"
Sleep 1.2s
Type "a"
Sleep 1.2s
Type "d"
Sleep 1.2s
Type "a"
Sleep 1.2s
Type "s"
Sleep 1.2s
Type "a"
Sleep 1.5s
Escape
Sleep 2.5s
Type "/exit"
Enter
Sleep 1s

# 2 · guard and revenue on generated data
Type "cd ~/sirus-demo && clear"
Enter
Sleep 500ms
Type "sirus guard gen --seed demo --actions 50"
Sleep 400ms
Enter
Sleep 3s
Type "sirus revenue gen --seed demo --payments 40 --checkouts 20 --invoices 10"
Sleep 400ms
Enter
Sleep 4s
Type "sirus"
Enter
Sleep 2.5s
Type "/guard eval feed --narrate"
Sleep 500ms
Enter
Sleep 12s
Type "/explain"
Sleep 500ms
Enter
Sleep 8s
Type "/exit"
Enter
Sleep 1s
Type "clear && sirus guard explain act_00053 --agent feed"
Sleep 400ms
Enter
Sleep 9s
Type "clear && sirus guard score feed"
Sleep 400ms
Enter
Sleep 7s

# 3 · revenue: detect, then evaluate
Type "clear && sirus revenue detect batch"
Sleep 400ms
Enter
Sleep 14s
Type "clear && sirus revenue eval batch"
Sleep 400ms
Enter
Sleep 14s

# 4 · a repo: scan, full-screen triage, watch, reconcile, baseline, badge, report
Type "cd clifintech && clear"
Enter
Sleep 500ms
Type "sirus scan contract/fixtures/chaos-repo"
Sleep 400ms
Enter
Sleep 14s
Type "clear && sirus triage --target contract/fixtures/chaos-repo"
Sleep 400ms
Enter
Sleep 2.5s
Type "a"
Sleep 1.5s
Type "j"
Sleep 800ms
Type "d"
Sleep 800ms
Type "not reachable from a request"
Sleep 600ms
Enter
Sleep 1.5s
Type "j"
Sleep 800ms
Type "/"
Sleep 600ms
Type "050"
Sleep 1.5s
Enter
Sleep 1.5s
Type "a"
Sleep 1.5s
Type "q"
Sleep 3s
Type "clear && sirus"
Enter
Sleep 2.5s
Type "/watch contract/fixtures/chaos-repo"
Sleep 500ms
Enter
Sleep 9s
Ctrl+C
Sleep 2.5s
Type "/exit"
Enter
Sleep 1s
Type "clear && sirus reconcile books42 --gen --orders 100 --seed 42"
Sleep 400ms
Enter
Sleep 3s
Type "sirus reconcile books42"
Sleep 400ms
Enter
Sleep 10s
Type "clear && sirus baseline set"
Sleep 400ms
Enter
Sleep 3s
Type "sirus scan"
Sleep 400ms
Enter
Sleep 60s
Type "clear && sirus badge"
Sleep 400ms
Enter
Sleep 4s
Type "sirus report"
Sleep 400ms
Enter
Sleep 4s
Type "sirus report --verify sirus-report-*.json"
Sleep 400ms
Enter
Sleep 7s
