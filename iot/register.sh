touch ubuntu_speaker_config.json
docker run --rm -v ${PWD}/ubuntu_speaker_config.json:/app/ubuntu_speaker_config.json iot_speaker:latest python raspberry_pi_speaker.py --register --username username --password password
