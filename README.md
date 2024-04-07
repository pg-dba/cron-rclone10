# cron-rclone

Запуск cron внутри Docker-контейнера<BR>
https://habr.com/ru/company/redmadrobot/blog/305364/<BR>
https://hub.docker.com/r/renskiy/cron/<BR>
https://github.com/renskiy/cron-docker-image<BR>

В контейнер необходимо передавать все строки crontab как ARG<BR>

Environment Variable: <pre><code>
DNSSERVER		169.254.169.250
MINIO_ENDPOINT_URL	http://u20d1h4:9000
MINIO_BUCKET		rclone
MINIO_ACCESS_KEY_ID	rclone-backup
MINIO_SECRET_ACCESS_KEY	P@ssw0rd
</code></pre>

Minio Policy: <pre><code>
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets",
                "s3:ListBucket",
                "s3:PutBucketPolicy",
                "s3:DeleteBucketPolicy",
                "s3:GetBucketPolicy"
            ],
            "Resource": [
                "arn:aws:s3:::rclone"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListMultipartUploadParts",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::rclone/*"
            ]
        }
    ]
}
</code></pre>

<HR>

Пример для "посмотреть":<BR>
<pre><code>docker run --rm -it -h cron-rsync \
  -e TZ='Europe/Moscow' -e CRONHOST=172.27.172.32 -e SSHPASSWORD=P@ssw0rd \
  -v /tmp:/cronwork \
  sqldbapg/cron-rsync \
  start-cron "\\*/1 \\* \\* \\* \\* env \\| sort 2>&1 1>>/var/log/cron.log" &

docker logs --follow $(docker ps | grep ' sqldbapg/cron-rsync' | awk '{ print $1 }')

docker exec -it $(docker ps | grep ' sqldbapg/cron-rsync' | awk '{ print $1 }') bash -c "crontab -l"

docker exec -it $(docker ps | grep ' sqldbapg/cron-rsync' | awk '{ print $1 }') bash

docker stop $(docker ps | grep ' sqldbapg/cron-rsync' | awk '{ print $1 }')
</code></pre>
