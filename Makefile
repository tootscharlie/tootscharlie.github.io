# Makefile
.DEFAULT: all
all: generate

run: generate
	hexo s

generate: clean
	hexo g

clean: clean_hexo
	rm -rf .deploy_git

clean_hexo:
	hexo clean

deploy: generate
	hexo d