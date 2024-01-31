@echo off

set DOCKER_COPY=python %~dp0..\..\..\docker_copy.py
set CONTAINER_NAME=my_dg

@REM docker build -t llvm-pass-container . && start /b docker run llvm-pass-container
@REM docker build . --tag dg:latest && docker run -ti dg:latest
docker build . --tag dg:latest
START docker run --name %CONTAINER_NAME% -ti dg:latest
pause
%DOCKER_COPY% /opt/dg/example/test.dot && %DOCKER_COPY% /opt/dg/example/test.ll && %DOCKER_COPY% /opt/dg/example/test.c && %DOCKER_COPY% /opt/dg/log.txt
docker stop %CONTAINER_NAME%
docker rm %CONTAINER_NAME%
@REM python ..\..\..\docker_copy.py /opt/dg/example/test.dot
