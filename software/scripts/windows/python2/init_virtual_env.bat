SET Python2=C:\Python27\python.exe
@echo off
if not exist %Python2% (
    echo "Python2 path not correct, check"
    EXIT /b
)

@echo on
%Python2% -m pip install virtualenv
%Python2% -m virtualenv "%~dp0..\..\..\venv2"
call "%~dp0..\..\..\venv2\Scripts\activate.bat"
python -m pip --no-input install -r "%~dp0requirements.txt"
