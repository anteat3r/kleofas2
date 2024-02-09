#!/bin/bash

if [[ $1 != "-u" ]]; then
  cd "/home/rosta/kleofas2"
  flutter build apk --split-per-abi
fi

file_path="/home/rosta/kleofas2/build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk"

if [[ -f $file_path ]]; then
  discord_channel_id=1115351529508053077
  if [[ $1 == "-r" || $2 == "-r" ]]; then
    discord_channel_id=1115723810214252586
  fi

  content=""
  message_index=$(expr index "${@}" -m)
  if [[ $message_index -gt 0 ]]; then
    content="${@:message_index+1}"
  fi

  filename="Kleofáš build "
  name_index=$(expr index "${@}" -n)
  if [[ $name_index -gt 0 ]]; then
    filename+=" ${@:name_index+1:1}"
  fi
  filename+=" $(date +'%y-%m-%d %H-%M-%S').apk"

  response=$(curl -X POST "https://discord.com/api/v10/channels/${discord_channel_id}/messages" \
    -H "Authorization: Bot MTEwODM3Nzk5MDAyODYxMTY5NQ.GGOPSO.CPmWGNg0lT5A3x72iJPdqF_kQ_0418mmVBpgm4" \
    -F "content=${content}" \
    -F "file=@${file_path};filename=${filename}" -o /dev/null -w "%{http_code}")

  echo "HTTP Status Code: $response"

else
  echo "APK file not found: ${file_path}"
fi
