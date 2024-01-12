# Steps to be followed for installing Microsoft ODBC Driver v17, v18 For PYTHON For Sql Server on Ubuntu
## Add Buildpacks
- The first buildpack: `https://github.com/heroku/heroku-buildpack-apt.git`
- The second buildpack: `https://github.com/heroku/heroku-buildpack-python.git`
- The last buildpack: `https://github.com/heroku-softtrends/heroku-python-pyodbc-buildpack.git`

## Add Aptfile File
	Aptfile file is mandatory, create a file called Aptfile in your project root folder. The Aptfile should contain the following .deb package names or download urls based on Ubuntu OS version (22.04/20.04) and ODBC Driver Version (18/17):
	### ODBC Driver 18 for SQL Server (Ubuntu 22.04)
			`unixodbc unixodbc-dev https://packages.microsoft.com/ubuntu/22.04/prod/pool/main/m/msodbcsql18/msodbcsql18_18.3.2.1-1_arm64.deb`
	### ODBC Driver 18 for SQL Server (Ubuntu 20.04)
			`unixodbc unixodbc-dev https://packages.microsoft.com/ubuntu/20.04/prod/pool/main/m/msodbcsql18/msodbcsql18_18.3.2.1-1_arm64.deb`
	### ODBC Driver 17 for SQL Server (Ubuntu 22.04)
			`unixodbc unixodbc-dev https://packages.microsoft.com/ubuntu/22.04/prod/pool/main/m/msodbcsql17/msodbcsql17_17.10.5.1-1_amd64.deb`
	### ODBC Driver 17 for SQL Server (Ubuntu 20.04)
			`unixodbc unixodbc-dev https://packages.microsoft.com/ubuntu/20.04/prod/pool/main/m/msodbcsql17/msodbcsql17_17.9.1.1-1_amd64.deb`
			
## Now deploy
```
$ git init
$ heroku git:remote -a <app_name>
$ git add --all
$ git commit -m "First commit"
$ git push heroku master
``` 

## Finally, check that everything is working
```
$ heroku open -a <heroku_app_name>
```

## References
[Getting started with python](https://devcenter.heroku.com/articles/getting-started-with-python?singlepage=true)

Ubuntu 22.04 .deb packages: [v17](https://packages.microsoft.com/ubuntu/22.04/prod/pool/main/m/msodbcsql17) [v18](https://packages.microsoft.com/ubuntu/22.04/prod/pool/main/m/msodbcsql18)
Ubuntu 20.04 .deb packages: [v17](https://packages.microsoft.com/ubuntu/22.04/prod/pool/main/m/msodbcsql17) [v18](https://packages.microsoft.com/ubuntu/22.04/prod/pool/main/m/msodbcsql18)

[Heroku python buildpack](https://github.com/heroku/heroku-buildpack-python)