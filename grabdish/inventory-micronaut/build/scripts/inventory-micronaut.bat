@rem
@rem Copyright 2015 the original author or authors.
@rem
@rem Licensed under the Apache License, Version 2.0 (the "License");
@rem you may not use this file except in compliance with the License.
@rem You may obtain a copy of the License at
@rem
@rem      https://www.apache.org/licenses/LICENSE-2.0
@rem
@rem Unless required by applicable law or agreed to in writing, software
@rem distributed under the License is distributed on an "AS IS" BASIS,
@rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
@rem See the License for the specific language governing permissions and
@rem limitations under the License.
@rem

@if "%DEBUG%" == "" @echo off
@rem ##########################################################################
@rem
@rem  inventory-micronaut startup script for Windows
@rem
@rem ##########################################################################

@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

set DIRNAME=%~dp0
if "%DIRNAME%" == "" set DIRNAME=.
set APP_BASE_NAME=%~n0
set APP_HOME=%DIRNAME%..

@rem Resolve any "." and ".." in APP_HOME to make it shorter.
for %%i in ("%APP_HOME%") do set APP_HOME=%%~fi

@rem Add default JVM options here. You can also use JAVA_OPTS and INVENTORY_MICRONAUT_OPTS to pass JVM options to this script.
set DEFAULT_JVM_OPTS=

@rem Find java.exe
if defined JAVA_HOME goto findJavaFromJavaHome

set JAVA_EXE=java.exe
%JAVA_EXE% -version >NUL 2>&1
if "%ERRORLEVEL%" == "0" goto execute

echo.
echo ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:findJavaFromJavaHome
set JAVA_HOME=%JAVA_HOME:"=%
set JAVA_EXE=%JAVA_HOME%/bin/java.exe

if exist "%JAVA_EXE%" goto execute

echo.
echo ERROR: JAVA_HOME is set to an invalid directory: %JAVA_HOME%
echo.
echo Please set the JAVA_HOME variable in your environment to match the
echo location of your Java installation.

goto fail

:execute
@rem Setup the command line

set CLASSPATH=%APP_HOME%\lib\inventory-micronaut-0.1.jar;%APP_HOME%\lib\micronaut-jms-core-2.0.0-M1.jar;%APP_HOME%\lib\micronaut-jdbc-ucp-4.0.4.jar;%APP_HOME%\lib\micronaut-jdbc-4.0.4.jar;%APP_HOME%\lib\micronaut-http-client-3.1.3.jar;%APP_HOME%\lib\micronaut-http-netty-3.1.3.jar;%APP_HOME%\lib\micronaut-websocket-3.1.3.jar;%APP_HOME%\lib\micronaut-http-client-core-3.1.3.jar;%APP_HOME%\lib\micronaut-messaging-3.1.3.jar;%APP_HOME%\lib\micronaut-runtime-3.1.3.jar;%APP_HOME%\lib\jta-1.1.jar;%APP_HOME%\lib\aqapi-19.3.0.0.jar;%APP_HOME%\lib\javax.json.bind-api-1.0.jar;%APP_HOME%\lib\json-20210307.jar;%APP_HOME%\lib\micronaut-validation-3.1.3.jar;%APP_HOME%\lib\micronaut-jackson-databind-3.1.3.jar;%APP_HOME%\lib\micronaut-jackson-core-3.1.3.jar;%APP_HOME%\lib\micronaut-json-core-3.1.3.jar;%APP_HOME%\lib\micronaut-http-3.1.3.jar;%APP_HOME%\lib\micronaut-context-3.1.3.jar;%APP_HOME%\lib\micronaut-aop-3.1.3.jar;%APP_HOME%\lib\micronaut-buffer-netty-3.1.3.jar;%APP_HOME%\lib\micronaut-inject-3.1.3.jar;%APP_HOME%\lib\javax.inject-1.jar;%APP_HOME%\lib\javax.annotation-api-1.3.2.jar;%APP_HOME%\lib\logback-classic-1.2.3.jar;%APP_HOME%\lib\jackson-datatype-jdk8-2.12.4.jar;%APP_HOME%\lib\jackson-datatype-jsr310-2.12.4.jar;%APP_HOME%\lib\jackson-databind-2.12.4.jar;%APP_HOME%\lib\jackson-annotations-2.12.4.jar;%APP_HOME%\lib\jackson-core-2.12.4.jar;%APP_HOME%\lib\micronaut-core-reactive-3.1.3.jar;%APP_HOME%\lib\micronaut-core-3.1.3.jar;%APP_HOME%\lib\jakarta.annotation-api-2.0.0.jar;%APP_HOME%\lib\netty-handler-proxy-4.1.69.Final.jar;%APP_HOME%\lib\netty-codec-http2-4.1.69.Final.jar;%APP_HOME%\lib\netty-codec-http-4.1.69.Final.jar;%APP_HOME%\lib\netty-codec-socks-4.1.69.Final.jar;%APP_HOME%\lib\netty-handler-4.1.69.Final.jar;%APP_HOME%\lib\netty-codec-4.1.69.Final.jar;%APP_HOME%\lib\netty-transport-4.1.69.Final.jar;%APP_HOME%\lib\netty-buffer-4.1.69.Final.jar;%APP_HOME%\lib\reactor-core-3.4.8.jar;%APP_HOME%\lib\reactive-streams-1.0.3.jar;%APP_HOME%\lib\slf4j-api-1.7.29.jar;%APP_HOME%\lib\snakeyaml-1.29.jar;%APP_HOME%\lib\validation-api-2.0.1.Final.jar;%APP_HOME%\lib\javax.jms-api-2.0.1.jar;%APP_HOME%\lib\ojdbc8-21.1.0.0.jar;%APP_HOME%\lib\ucp-21.1.0.0.jar;%APP_HOME%\lib\rsi-21.1.0.0.jar;%APP_HOME%\lib\oraclepki-21.1.0.0.jar;%APP_HOME%\lib\osdt_core-21.1.0.0.jar;%APP_HOME%\lib\osdt_cert-21.1.0.0.jar;%APP_HOME%\lib\simplefan-21.1.0.0.jar;%APP_HOME%\lib\ons-21.1.0.0.jar;%APP_HOME%\lib\orai18n-21.1.0.0.jar;%APP_HOME%\lib\xdb-21.1.0.0.jar;%APP_HOME%\lib\xmlparserv2-21.1.0.0.jar;%APP_HOME%\lib\netty-resolver-4.1.69.Final.jar;%APP_HOME%\lib\netty-common-4.1.69.Final.jar;%APP_HOME%\lib\jakarta.inject-api-2.0.1.jar;%APP_HOME%\lib\logback-core-1.2.3.jar;%APP_HOME%\lib\commons-pool2-2.10.0.jar


@rem Execute inventory-micronaut
"%JAVA_EXE%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %INVENTORY_MICRONAUT_OPTS%  -classpath "%CLASSPATH%" io.micronaut.data.examples.Application %*

:end
@rem End local scope for the variables with windows NT shell
if "%ERRORLEVEL%"=="0" goto mainEnd

:fail
rem Set variable INVENTORY_MICRONAUT_EXIT_CONSOLE if you need the _script_ return code instead of
rem the _cmd.exe /c_ return code!
if  not "" == "%INVENTORY_MICRONAUT_EXIT_CONSOLE%" exit 1
exit /b 1

:mainEnd
if "%OS%"=="Windows_NT" endlocal

:omega
