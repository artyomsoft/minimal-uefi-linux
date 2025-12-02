#! /bin/bash
sudo docker run --platform linux/amd64 --rm -it --workdir /result -v $(pwd):/result debian:bookworm ./build-linux.sh