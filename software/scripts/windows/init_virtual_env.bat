python.exe -m pip install virtualenv
cd "%~dp0..\.."
python -m venv venv
call ".\venv\Scripts\activate.bat"
python -m pip --no-input install -r "%~dp0..\requirements.txt"
