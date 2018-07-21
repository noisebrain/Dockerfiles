# docker build . -f test-args.dockerfile --build-arg MYVAR=456 -t test-args
# docker run -it --rm -e MYVAR=9999 test-args
FROM alpine
ARG MYVAR
RUN echo MYVAR=$MYVAR
CMD ["sh"]	# bash is not in alpine
