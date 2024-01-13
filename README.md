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

> Note that you will have to pull the model you want to use using the `VLMAPull <model>` command before using it or an error will be thrown.

## vimplug plugin

Open your `.vimrc` file and add the following code between the `call plug#begin('~/.vim/plugged')` and `call plug#end()` statements:

    Plug 'Dr4x14913/vim-llama'

Then open vim and run:

    :PlugInstall


# Configuration
You can tune the following variables:

| Name | Default value | What this is |
|------|:-------------:|-----------------|
| g:vim_llama_context_size | 20 | Size of the context window: number of lines above your cursor that will be taken into account when start function is called. If you are in v mode, only selected lines will be taken into account. |
| g:vim_llama_model | codellama | Model that you want to use (ex: llama2, codellama:python ...) |
| g:vim_llama_ip | localhost | IP address of the Llama server |
| g:vim_llama_port | 11434 | Port number for the Llama server |

# Use it

You can type `:VLMAStart` command and the model will continue your code based on the `g:vim_llama_context_size` lines before the one you are on at this time. \
You can alose type this command in visual mode, in this case, only the selected lines will be passed to the model.

The default behaviour of the model will be to continue your code, if you want to do different stuff, you can run:

    :VLMAStart <Begining instructions>, <End instructions>
This will prompt:

    <Begining instructions>
    ```
    # Lines that you selected in visual mode
    # or lines that are in the context window
    ```
    <End insructions>

## Available commands

| Command name | Option | Behaviour |
|--------------|--------|-----------|
| VLMAStart    | [\<range>], [\<prompt start>], [\<prompt end>]  | Starts the completion as explained above. |
| VLMAStop     | -      | Stops a running completion process. |
| VLMAPull     | model  | Pulls an ollama model. |
| VLMALogs     | -      | Displays the logs of the last completion. |



