docker run --detach \
  --name wg-easy \
  --env LANG=chs \
  --env WG_HOST={your_ip_addr} \
  --env PASSWORD_HASH='$2a$12$jTwFJ8k7hlEFDoGKd2fRuejUv82i7ilzYN6fyOQclblNcHUjLvL9O' \
  --env PORT=51821 \
  --env WG_PORT=51820 \
  --volume ~/.wg-easy:/etc/wireguard \
  --publish 51820:51820/udp \
  --publish 51821:51821/tcp \
  --cap-add NET_ADMIN \
  --cap-add SYS_MODULE \
  --sysctl 'net.ipv4.conf.all.src_valid_mark=1' \
  --sysctl 'net.ipv4.ip_forward=1' \
  --restart unless-stopped \
  ghcr.io/wg-easy/wg-easy

 # This_is_wiregrand_password