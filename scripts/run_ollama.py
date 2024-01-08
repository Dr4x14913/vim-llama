#! /usr/bin/python3
import json
from os import system, path
from sys import argv
from subprocess import Popen, PIPE

with open('.vimllama.ctx', 'r') as f:
  prompt = f.read()
model = "codellama"
if len(argv) >= 2:
  model = argv[1]

curl_dict = {
  'model': model,
  'prompt': prompt
}

cmd = ["curl --no-buffer -X POST http://localhost:11434/api/generate -d \'"+json.dumps(curl_dict)+"\' 2>/dev/null"]
system('rm -f .vimllama.stop')
system('rm -f .vimllama.resp && touch .vimllama.resp')
system('docker start ollama > /dev/null')

proc = Popen(cmd, shell=True, stdout=PIPE)
pid  = proc.pid
while proc.poll() is None:
    if path.isfile(".vimllama.stop"):
        proc.kill()
        system(f"kill -9 {pid + 1}")

    line = proc.stdout.readline()
    print("test",line.rstrip())
    if not line:
        break
    with open(".vimllama.resp", "a") as f:
        f.write(line.decode('utf-8'))
