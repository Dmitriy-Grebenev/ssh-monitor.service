# ssh-monitor.service

Для выполнения описанной задачи можно создать службу systemd, которая постоянно отслеживает подключенных по ssh пользователей и записывает их в отдельный файл. Вот пример того, как создать такую службу:

Создайте новый файл /etc/systemd/system/ssh-monitor.service со следующим содержимым:

    [Unit]
    Description=SSH user monitor service

    [Service]
    ExecStart=/usr/bin/bash -c 'journalctl -f _SYSTEMD_UNIT=sshd.service | grep "Accepted publickey for" >> /var/log/ssh-users.log'
    Restart=always

    [Install]
    WantedBy=multi-user.target

Эта служба будет использовать journalctl для мониторинга журналов sshd, отфильтровывать события входа и добавлять их в отдельный файл журнала /var/log/ssh-users.log. Опция Restart=always гарантирует, что служба будет перезапущена в случае сбоя или остановки по какой-либо причине.

Чтобы включить службу, выполните следующую команду:

    sudo systemctl enable ssh-monitor.service

Чтобы запустить службу немедленно, выполните команду:

    sudo systemctl start ssh-monitor.service

Для реализации функции отслеживания входа пользователей в систему можно создать отдельный сценарий, который периодически проверяет файл журнала пользователей и отправляет уведомление по электронной почте, если какой-либо пользователь не входил в систему в течение 3 месяцев.

Вот пример такого сценария, который вы можете поместить в /usr/local/bin/ssh-user-check.sh:

    #!/bin/bash

    # Path to the ssh users log file
    SSH_USERS_LOG=/var/log/ssh-users.log

    # Email address of the administrator
    ADMIN_EMAIL=admin@example.com

    # Calculate the date three months ago
    THREE_MONTHS_AGO=$(date -d "-3 months" +"%b %_d")

    # Search for any users who haven't logged in for 3 months
    INACTIVE_USERS=$(grep "Accepted publickey for" "$SSH_USERS_LOG" | awk '{print $1, $2}' | sort -u | awk -v tma="$THREE_MONTHS_AGO" '$2 < tma {print $1}')

    # If there are any inactive users, send an email notification to the administrator
    if [ -n "$INACTIVE_USERS" ]; then
        echo "The following ssh users haven't logged in for 3 months: $INACTIVE_USERS" | mailx -s "Inactive ssh users" "$ADMIN_EMAIL"
    fi

Чтобы запланировать периодическое выполнение сценария, вы можете создать задание cron, выполнив следующую команду:

    sudo crontab -e

Добавьте следующую строку в конец файла, чтобы запланировать выполнение сценария каждый день в полночь:

    0 0 * * * /usr/local/bin/ssh-user-check.sh

При такой настройке служба ssh-monitor.service systemd будет постоянно отслеживать подключенных по ssh пользователей и записывать их в файл ssh-users.log. Сценарий ssh-user-check.sh будет периодически проверять файл журнала и уведомлять администратора, если какой-либо пользователь не входил в систему в течение 3 месяцев.
