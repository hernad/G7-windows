
set GREENBOX_INSTALL_PATH=%1
set TASK_USER=%2
set TASK_PASSWORD=%3


REM SchTasks /Create /F /SC ONSTART /TN "Hello world" /ru %TASK_USER% /rp %TASK_PASSWORD% ^
REM     /TR "\"c:\Program Files\Git\bin\bash.exe\"  --login -i \"%GREENBOX_INSTALL_PATH%\hello.sh\" "


SchTasks /Create /F /SC ONSTART /TN "sshd greenbox 22"  /ru %TASK_USER% /rp %TASK_PASSWORD% /RL HIGHEST ^
    /TR "\"C:\Program Files\Git\bin\bash.exe\"  --login -i \"%GREENBOX_INSTALL_PATH%\sshd.sh\" 22"


echo windows 7 UDP port 53
netsh advfirewall firewall add rule name="DNS" dir=in action=allow protocol=UDP localport=53

echo windows 7 port 80
netsh advfirewall firewall add rule name="HTTP" dir=in action=allow protocol=TCP localport=80

echo windows 7 port 443
netsh advfirewall firewall add rule name="HTTPS" dir=in action=allow protocol=TCP localport=443

echo windows 7 port 22
netsh advfirewall firewall add rule name="ssh windows host" dir=in action=allow protocol=TCP localport=22

echo windows 7 port 2222
netsh advfirewall firewall add rule name="ssh greenbox host" dir=in action=allow protocol=TCP localport=2222

echo windows 7 port 2376
netsh advfirewall firewall add rule name="docker admin port" dir=in action=allow protocol=TCP localport=2376

echo run tasks immediately
SchTasks /Run /I /TN "sshd greenbox 22"
