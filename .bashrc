function java17() {
	export JAVA_HOME="C:\java\jdk-17.0.7" 
	export PATH=${JAVA_HOME}/bin:$PATH
}

export -f java17

function java8() {
	export JAVA_HOME="C:\Program Files (x86)\Java\jdk1.8.0_202" 
	export PATH=${JAVA_HOME}/bin:$PATH
}

export -f java8

alias direnv="/C/Tools/direnv.exe"
# direnv
eval "$(direnv hook bash)"

alias gst='git status'
alias gl='git pull'
alias gp='git push'
alias ga='git add'
alias gc='git commit -v -m'
alias gco='git checkout'
alias gcob='git checkout -b'
