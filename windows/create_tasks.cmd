
set TASK_USER=greenbox
set TASK_PASSWORD=test01


SchTasks /Create /F /SC ONSTART /TN "Hello world" /ru %TASK_USER% /rp %TASK_PASSWORD% ^
     /TR "\"c:\Program Files\Git\bin\bash.exe\"  --login -i \"C:\Program Files\G7_greenbox\hello.sh\" " 

SchTasks /Create /F /SC ONSTART /TN "sshd greenbox 22"  /ru %TASK_USER% /rp %TASK_PASSWORD%  ^
    /TR "\"c:\Program Files\Git\bin\bash.exe\"  --login -i \"C:\Program Files\G7_greenbox\sshd.sh\" " 

SchTasks /Create /F /SC ONSTART /TN "sshd greenbox admin 2222"  /ru %TASK_USER% /rp %TASK_PASSWORD% /RL HIGHEST ^
    /TR "\"C:\Program Files\Git\bin\bash.exe\"  --login -i \"C:\Program Files\G7_greenbox\sshd.sh\" 2222" 

echo windows xp port 2222
netsh firewall add portopening TCP 2222 "ssh admin port"

echo windows 7 port 2222
netsh advfirewall firewall add rule name="ssh admin port" dir=in action=allow protocol=TCP localport=2222

echo windows xp port 22
netsh firewall add portopening TCP 22 "ssh admin port"

echo windows 7 port 22
netsh advfirewall firewall add rule name="ssh admin port" dir=in action=allow protocol=TCP localport=22

echo run tasks immediately
SchTasks /Run /I /TN "sshd greenbox 22" 
SchTasks /Run /I /TN "sshd greenbox admin 2222"
