# Using ee with python for image download

Create a python virtual environment
```sh
conda deactivate
mkdir -p $HOME/venv
python3 -m venv $HOME/venv/eegis
source $HOME/venv/eegis/bin/activate
```


Check python version
```sh
python --version
```

Update and install modules
```sh
pip install --upgrade pip
#/usr/local/opt/python@3.9/bin/python3.9 -m pip install --upgrade pip
pip3 install numpy matplotlib earthengine-api rasterio gcloud folium selenium


```


Download gcloud Command Line Interpreter from: https://cloud.google.com/sdk/docs/install

```sh
mkdir ~/bin
cd ~/bin
tar -xzvf ~/Downloads/google-cloud-cli-447.0.0-darwin-arm.tar.gz
```

Run the install script

```sh
./google-cloud-sdk/install.sh
```

then run the init script:

```sh
bin/google-cloud-sdk/bin/gcloud init
```
Now we can run the earthengine commandline tool and authenticate
```sh
earthengine authenticate
```

Now we go to our target directory and run the script:

```sh
cd proyectos/Tropical-Glaciers/T6.1-SA-01-VE-01-Cordillera-Merida/sandbox 
python ../inc/download-ee-image.py

```
