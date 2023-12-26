#!/bin/bash

if [[ $1 != "-u" ]]; then
  cd "/home/rosta/kleofas2"
  flutter build apk --split-per-abi
fi

file_path="/home/rosta/kleofas2/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"

if [[ -f $file_path ]]; then
  discord_channel_id=1115351529508053077
  if [[ $2 == "-r" ]]; then
    discord_channel_id=1115723810214252586
  fi

  content=""
  message_index=$(expr index "${@}" -m)
  if [[ $message_index -gt 0 ]]; then
    content="${@:message_index+1}"
  fi

  filename="kleofas-build-"
  name_index=$(expr index "${@}" -n)
  if [[ $name_index -gt 0 ]]; then
    filename+="-${@:name_index+1:1}"
  fi
  filename+="-$(date +'%y-%m-%d_%H-%M-%S').apk"

  content+=" https://kleofas.eu/release/$filename"
  cd /home/rosta/kleofas2/build/app/outputs/flutter-apk
  echo $filename
  mv app-arm64-v8a-release.apk $filename
  scp $filename root@194.233.170.207:/root/web/release
  response=$(curl -X POST "https://discord.com/api/v10/channels/${discord_channel_id}/messages" \
    -H "Authorization: Bot MTEwODM3Nzk5MDAyODYxMTY5NQ.Gi7kyW.1Yvqi1gU-gqX0dCJ_atXFY1Xot-rukoLSsD0_E" \
    -F "content=${content}" \
    -o /dev/null -w "%{http_code}")

  echo "HTTP Status Code: $response"

else
  echo "APK file not found: ${file_path}"
fi
