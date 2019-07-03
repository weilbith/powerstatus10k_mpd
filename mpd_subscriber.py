#!/usr/bin/env python2

from musicpd import MPDClient
import os

fifo_name = os.getenv("XDG_RUNTIME_DIR", "/tmp") + "/powerstatus10k/fifos/mpd"
mpd_host = os.getenv("MPD_HOST", "127.0.0.1")
mpd_port = os.getenv("MPD_PORT", "6600")

client = MPDClient()
client.connect(mpd_host, mpd_port)

while True:
    client.send_idle()
    client.fetch_idle()

    status = client.status()
    state = status["state"] if "state" in status else "stop"

    song = client.currentsong()
    artist = song["artist"] if "artist" in song else "Unknown Artist"
    title = song["title"] if "title" in song else "Unknown Title"

    # Do this here to avoid problems on a deleted FIFO during runtime.
    if not os.path.exists(fifo_name):
        os.mkfifo(fifo_name)

    with open(fifo_name, "w") as fifo:
        fifo.write(f"{state}:{artist}:{title}")
