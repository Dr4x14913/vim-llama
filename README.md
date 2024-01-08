# vim-llama
vim-llama is a vimPlug plugin for self hosted codellama completion

# Requirements
You will need to have docker as well as vim installed.

# Install

## ollama local server
Pull the [ollama docker image](https://hub.docker.com/r/ollama/ollama)

    docker pull ollama/ollama

And the run it on the port `11434` in a container named `ollama`:

    docker run -d -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama


## vimplug plugin

Open your `.vimrc` file and add the following code between the `call plug#begin('~/.vim/plugged')` and `call plug#end()` statements:
    
    Plug 'Dr4x14913/vim-llama'

Then open vim and run:

    :PlugInstall

To run it you have to use the `VLMAStart` command. The `VLMAStop` command will kill the running process. 

# Configuration
You can tune the following variables:

| Name | Default value | What this is | 
|------|:-------------:|-----------------|
| g:vim_llama_context_size | 20 | Size of the context window (number of line above your cursor when start function is called) |
| g:vim_llama_model | codellama | Model that you want to use (ex: llama2, codellama:pyhton ...) |