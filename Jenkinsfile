pipeline {
  agent any
//  environment {       
//    EXAMPLE_ENVIRONMENT_VARIABLE = credentials('example-var-name-defined-in-jenkins-credentials-system')
//  }

  stages {
    stage('Build') {        
      steps {
        git branch: 'unit-testing', url: "https://github.com/UCSCLibrary/digital-collections-dev-docker.git"
        sh 'docker-compose build; docker-compose up -d'
      }
    }
    stage('Test') {
      steps {
          sh 'docker exec hycruz bundle exec rspec spec/unit; docker exec hycruz bundle exec rspec spec/integration'
      }
    }
    stage('Deploy') {
      steps {
        git branch: "${BRANCH_NAME}", url: "https://github.com/UCSCLibrary/digital-collections-ucsc-library-digital-collections"
        sh 'cap ${BRANCH_NAME/master/production} deploy'
      }
    }
    stage('AcceptanceTest') {
      steps {
        sh 'bundle install; bundle exec rspec spec/acceptance'
      }
      post {
        unsuccessful {
          sh 'cap ${BRANCH_NAME/master/production} deploy:rollback'
        }
      }
    }
  }
}
