# Steps to be followed for installing Microsoft ODBC Driver v17, v18 For PYTHON For Sql Server on Ubuntu
## Add Buildpacks
- The first buildpack: `https://github.com/heroku/heroku-buildpack-apt.git`
- The second buildpack: `https://github.com/heroku/heroku-buildpack-python.git`
- The last buildpack: `https://github.com/heroku-softtrends/heroku-python-pyodbc-buildpack.git`

## Supported Heroku stacks
This buildpack works on every Heroku stack below, since `bin/compile` and `.profile.d/configure-odbc.sh` detect the installed driver dynamically rather than hard-coding a path or version. Pick the Aptfile entry further down that matches the Ubuntu version behind your stack:

| Heroku stack | Ubuntu version | Status |
|---|---|---|
| `heroku-26` | 26.04 LTS | Supported (newest) |
| `heroku-24` | 24.04 LTS | Supported — **default stack for new apps** |
| `heroku-22` | 22.04 LTS | Deprecated (supported through Apr 2027) |
| `heroku-20` | 20.04 LTS | End-of-life (support ended Apr 2025) |
| `heroku-18` | 18.04 LTS | End-of-life |
| `heroku-16` | 16.04 LTS | End-of-life |

Deprecated/end-of-life stacks still build with this buildpack, but Heroku no longer patches or supports the base image itself — move new and actively-maintained apps to `heroku-24` or `heroku-26`.

Check and set your app's stack with:
```
$ heroku stack -a <app_name>
$ heroku stack:set heroku-24 -a <app_name>
```

## Supported Python versions
This is governed by Heroku's Python buildpack (via your `.python-version`/`runtime.txt`), not by this buildpack — but since `mssql-django`/`pyodbc` apps are usually long-lived, it's worth pinning to a version that's still supported:

| Python version | Heroku status |
|---|---|
| 3.15 | Supported |
| 3.14 | Supported — default for new apps |
| 3.13 | Supported |
| 3.12 | Supported |
| 3.11 | Supported |
| 3.10 | Deprecated |
| 3.9 | No longer supported |
| 3.8 | No longer supported |

"No longer supported" apps keep running but can't be rebuilt/redeployed until upgraded. Add a `.python-version` file (e.g. containing `3.13`) to your project root to pin the version explicitly.

## Set Django version minimum from 4.2 and higher in requirement.txt
```
django>=4.2,<5.1
gunicorn>=21.2,<22.0
dj-database-url>=2.0,<3.0
whitenoise[brotli]>=6.0,<7.0
mssql-django
pyodbc
```

## Add Aptfile File
Aptfile file is mandatory, create a file called Aptfile in your project root folder. The Aptfile should contain the following .deb package names or download urls based on Ubuntu OS version (24.04/22.04/20.04) and ODBC Driver Version (18/17). Heroku dynos run on `amd64`, so always use the `amd64` package, never `arm64` (the previous version of this README mistakenly linked `arm64` builds for the v18/24.04 and v18/22.04 entries — those will fail to install on a real dyno).

- ODBC Driver 18 for SQL Server (Ubuntu 26.04 / `heroku-26`) — latest: 18.7.1.1
```
unixodbc
unixodbc-dev
https://packages.microsoft.com/ubuntu/26.04/prod/pool/main/m/msodbcsql18/msodbcsql18_18.7.1.1-1_amd64.deb
```

- ODBC Driver 18 for SQL Server (Ubuntu 24.04 / `heroku-24`) — latest: 18.7.1.1
```
unixodbc
unixodbc-dev
https://packages.microsoft.com/ubuntu/24.04/prod/pool/main/m/msodbcsql18/msodbcsql18_18.7.1.1-1_amd64.deb
```

- ODBC Driver 18 for SQL Server (Ubuntu 22.04 / `heroku-22`) — latest: 18.7.1.1
```
unixodbc
unixodbc-dev
https://packages.microsoft.com/ubuntu/22.04/prod/pool/main/m/msodbcsql18/msodbcsql18_18.7.1.1-1_amd64.deb
```

- ODBC Driver 18 for SQL Server (Ubuntu 20.04 / `heroku-20`, deprecated) — latest: 18.5.1.1
```
unixodbc
unixodbc-dev
https://packages.microsoft.com/ubuntu/20.04/prod/pool/main/m/msodbcsql18/msodbcsql18_18.5.1.1-1_amd64.deb
```

- ODBC Driver 17 for SQL Server (Ubuntu 24.04 / `heroku-24`) — latest: 17.11.1.1
```
unixodbc
unixodbc-dev
https://packages.microsoft.com/ubuntu/24.04/prod/pool/main/m/msodbcsql17/msodbcsql17_17.11.1.1-1_amd64.deb
```

- ODBC Driver 17 for SQL Server (Ubuntu 22.04 / `heroku-22`) — latest: 17.11.1.1
```
unixodbc
unixodbc-dev
https://packages.microsoft.com/ubuntu/22.04/prod/pool/main/m/msodbcsql17/msodbcsql17_17.11.1.1-1_amd64.deb
```

- ODBC Driver 17 for SQL Server (Ubuntu 20.04 / `heroku-20`, deprecated) — latest: 17.10.6.1
```
unixodbc
unixodbc-dev
https://packages.microsoft.com/ubuntu/20.04/prod/pool/main/m/msodbcsql17/msodbcsql17_17.10.6.1-1_amd64.deb
```

> Driver 18 is Microsoft's actively developed driver and is recommended for new apps; Driver 17 is kept here only for apps that still depend on its (slightly different) default TLS/encryption behavior. Microsoft does **not** publish a Driver 17 package for Ubuntu 26.04 — apps on `heroku-26` must use Driver 18. Versions above are current as of this writing — check the [package index](https://packages.microsoft.com/ubuntu/) for newer point releases before deploying, and bump the version/URL in your Aptfile when one is available, since `bin/compile` always picks up whichever version the apt buildpack actually installed.

## Default Database Configuration With ODBC Driver 18 in settings.py
```
DATABASES = {
       "default": {
             "ENGINE" : "mssql",
             "NAME": "dbname",
             "HOST" : "server_url/ip",
             "PORT" : "1433",
             "USER": "user_id",
             "PASSWORD": "password",
             "Trusted_Connection": "yes",
             "OPTIONS": {
			    "driver": "ODBC Driver 18 for SQL Server"
		     }
	    }
    }
```

## Sample Code To Query Data From views.py
```
from django.shortcuts import render
from django.http import HttpRequest
from django.db import connections

def index(request):
	activities = []
    conn = connections.create_connection('default')
    cursor = conn.cursor()
    cursor.execute("SELECT [activityid],[activitydescription],[activityname] FROM [dbo].[activity]")
    for row in cursor.fetchall():
        activities.append({"activityid": row[0], "activityname": row[1], "activitydescription": row[2]})
    conn.close()
    return render(
        request,
        'index.html',
        {
            'activities': activities
        }
    )
```

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

[Heroku stack list / which Ubuntu version each stack uses](https://devcenter.heroku.com/articles/stack)

[Heroku Python version support](https://devcenter.heroku.com/articles/python-support)

Ubuntu 26.04 (`heroku-26`) .deb packages: [v18 only](https://packages.microsoft.com/ubuntu/26.04/prod/pool/main/m/msodbcsql18)

Ubuntu 24.04 (`heroku-24`) .deb packages: [v17](https://packages.microsoft.com/ubuntu/24.04/prod/pool/main/m/msodbcsql17), [v18](https://packages.microsoft.com/ubuntu/24.04/prod/pool/main/m/msodbcsql18)

Ubuntu 22.04 (`heroku-22`) .deb packages: [v17](https://packages.microsoft.com/ubuntu/22.04/prod/pool/main/m/msodbcsql17), [v18](https://packages.microsoft.com/ubuntu/22.04/prod/pool/main/m/msodbcsql18)

Ubuntu 20.04 (`heroku-20`, deprecated) .deb packages: [v17](https://packages.microsoft.com/ubuntu/20.04/prod/pool/main/m/msodbcsql17), [v18](https://packages.microsoft.com/ubuntu/20.04/prod/pool/main/m/msodbcsql18)

[Heroku python buildpack](https://github.com/heroku/heroku-buildpack-python)