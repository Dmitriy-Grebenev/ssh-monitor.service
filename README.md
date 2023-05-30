# ssh-monitor.service

Создайте новый файл /etc/systemd/system/ssh-monitor.timer со следующим содержимым:

    [Unit]
    Description=SSH user monitor timer

    [Timer]
    OnBootSec=1min
    OnUnitActiveSec=1min

    [Install]
    WantedBy=timers.target

Создайте новый файл /etc/systemd/system/ssh-monitor.service со следующим содержимым:

    [Unit]
    Description=SSH user monitor service

    [Service]
    ExecStart=/usr/bin/bash -c 'journalctl -f _SYSTEMD_UNIT=sshd.service | grep -E "Accepted (publickey|password) for" >> /var/log/ssh-users.log'

    [Install]
    WantedBy=multi-user.target
    
Блок ssh-monitor.timer указывает, что он должен срабатывать каждую минуту после загрузки и каждую минуту, когда служба активна.

Включите таймер и службу, выполнив следующие команды:

    sudo systemctl enable ssh-monitor.timer
    sudo systemctl enable ssh-monitor.service
    
Запустите таймер:

    sudo systemctl start ssh-monitor.timer

Создайте новый файл /usr/local/bin/ssh-user-check.sh со следующим содержимым:

    #!/bin/bash

    # Path to the ssh users log file
    SSH_USERS_LOG=/var/log/ssh-users.log

    # Email address of the administrator
    ADMIN_EMAIL=admin@example.com

    # Calculate the date three months ago
    THREE_MONTHS_AGO=$(date -d "-3 months" +"%b %_d")

    # Search for any users who haven't logged in for 3 months
    INACTIVE_USERS=$(grep -E "Accepted (publickey|password) for" "$SSH_USERS_LOG" | awk '{print $1, $2}' | sort -u | awk -v tma="$THREE_MONTHS_AGO" '$2 < tma {print $1}')

    # If there are any inactive users, send an email notification to the administrator
    if [ -n "$INACTIVE_USERS" ]; then
        echo "The following ssh users haven't logged in for 3 months: $INACTIVE_USERS" | mailx -s "Inactive ssh users" "$ADMIN_EMAIL"
    fi

Сделайте сценарий исполняемым:
 
    sudo chmod +x /usr/local/bin/ssh-user-check.sh

Запланируйте выполнение сценария на полночь каждый день, добавив задание cron:

    sudo crontab -e

Добавьте в конец файла следующую строку:

    0 0 * * * /usr/local/bin/ssh-user-check.sh

В итоге ssh-monitor.timer будет запускать службу ssh-monitor.service каждую минуту, а служба будет обновлять файл журнала с входами как с открытым ключом, так и с паролем. Кроме того, скрипт ssh-user-check.sh будет запускаться ежедневно, чтобы уведомить администратора по электронной почте, если какой-либо пользователь не входил в систему в течение 3 месяцев.
