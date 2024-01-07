#! /usr/bin/python3
from os import system
from sys import argv
import json
from subprocess import Popen, PIPE, STDOUT

with open('.codellama.ctx', 'r') as f:
  prompt = f.read()
model = "codellama"
if len(argv) >= 2:
  model = argv[1]

curl_dict = {
  'model': model,
  'prompt': prompt
}

cmd = "curl -X POST http://localhost:11434/api/generate -d '" + json.dumps(curl_dict) + "'"
print(cmd)
system('rm -f .codellama.stopped')
system('docker start ollama')
system(cmd + " > .codellama.resp")
