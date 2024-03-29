#! /usr/bin/python3
import json
from os import system, path, kill
from signal import SIGKILL
from subprocess import Popen, PIPE, run
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('--model', type=str, default="codellama:latest")
parser.add_argument('--path', type=str)
parser.add_argument('--ip', type=str, default="localhost")
parser.add_argument('--port', type=str, default="11434")
args = parser.parse_args()

if args.path is None:
    raise ValueError("--path option is required")
# If path dir doesnt exits throw an error as well
if not path.exists(args.path):
    raise ValueError(f"{args.path} does not exist")

with open(f'{args.path}/.vimllama.ctx', 'r') as f:
    prompt = f.read()

curl_dict = {
  'model': args.model,
  'prompt': prompt
}
cmd = [f"curl --no-buffer -X POST http://{args.ip}:{args.port}/api/generate -d \'"+json.dumps(curl_dict)+"\' 2>/dev/null"]
system(f'rm -f {args.path}/.vimllama.stop')
system(f'rm -f {args.path}/.vimllama.resp && touch {args.path}/.vimllama.resp')

proc = Popen(cmd, shell=True, stdout=PIPE)
ppid  = proc.pid
pids = run(["pgrep", "-P", f"{ppid}"], capture_output=True).stdout.decode('utf-8').split('\n')[:-1]

while proc.poll() is None:
    if path.isfile(f"{args.path}/.vimllama.stop"):
        proc.kill()
        for pid in pids:
            kill(int(pid), SIGKILL)

    line = proc.stdout.readline()
    print(line.rstrip())
    if not line:
        break

    with open(f"{args.path}/.vimllama.resp", "a") as f:
        f.write(line.decode('utf-8'))
