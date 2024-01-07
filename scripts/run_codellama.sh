#! /usr/bin/bash
rm -f .codellama.stopped
docker start ollama
docker_run.pl noit CODE ollama run codellama:python '$(cat .codellama.ctx)' > .codellama.resp
touch .codellama.stopped

