pipeline {
    agent any

    parameters {
        choice(
            choices: 'dev\ntest\nprod',
            description: 'Select the environment for deployment',
            name: 'ENVIRONMENT'
        )
    }

    options {
        timestamps()
        timeout(time: 1, unit: 'HOURS')
    }

    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', credentialsId: 'git', url: 'git@github.com:krishnavamshi933/myprojectdir.git'
            }
        }

        stage('Setup Virtual Environment') {
            steps {
                sh 'python3 -m venv myprojectenv'
                sh 'source myprojectenv/bin/activate'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'pip install -r requirements.txt'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'python manage.py test'
            }
        }

        stage('Build and Deploy') {
            steps {
                script {
                    def servers

                    switch (params.ENVIRONMENT) {
                        case 'dev':
                            servers = ['dev-server']
                            break
                        case 'test':
                            servers = ['test-server']
                            break
                        case 'prod':
                            servers = ['prod-server']
                            break
                        default:
                            error('Invalid environment selected')
                    }

                    for (server in servers) {
                        echo "Deploying to ${server}"
                        deployToServer(server)
                    }
                }
            }
        }
    }

  //  post {
    //    always {
            // Add any post-build actions here
            // For example, archiving artifacts or sending notifications
      //  }
  //  }
}

def deployToServer(server) {
    stage('Setup Virtual Environment') {
        sshagent(credentials: ['git']) {
            sh "ssh user@${server} 'python3 -m venv myprojectenv'"
        }
    }

    stage('Install Dependencies') {
        sshagent(credentials: ['git']) {
            sh "ssh user@${server} 'source myprojectenv/bin/activate && pip install -r requirements.txt'"
        }
    }

    stage('Run Migrations') {
        sshagent(credentials: ['git']) {
            sh "ssh user@${server} 'source myprojectenv/bin/activate && cd myproject && python manage.py migrate'"
        }
    }

    stage('Collect Static Files') {
        sshagent(credentials: ['git']) {
            sh "ssh user@${server} 'source myprojectenv/bin/activate && cd myproject && python manage.py collectstatic --noinput'"
        }
    }

    stage('Run Gunicorn Daemon') {
        sshagent(credentials: ['git']) {
            sh "ssh user@${server} 'source myprojectenv/bin/activate && cd myproject && gunicorn myproject.wsgi:application --bind=127.0.0.1:8000 --daemon'"
        }
    }

    stage('Restart Nginx') {
        sshagent(credentials: ['git']) {
            sh "ssh user@${server} 'sudo systemctl restart nginx'"
        }
    }
}
