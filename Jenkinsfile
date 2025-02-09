pipeline {
  agent none
  parameters {
    booleanParam(name: 'CLEANBUILD', defaultValue: false, description: 'Enable Clean Build ?')
    string(name: 'ECRURL', defaultValue: '908027399517.dkr.ecr.ap-south-1.amazonaws.com', description: 'Please Enter your Docker ECR REGISTRY URL without https?')
    string(name: 'BASEREPO', defaultValue: 'thousif123981/demobaseimage', description: 'Please Enter your Docker Base Repo Name?')
    string(name: 'APPREPO', defaultValue: 'demoappimage', description: 'Please Enter your Docker App Repo Name?')
    string(name: 'REGION', defaultValue: 'ap-south-1', description: 'Please Enter your AWS Region?')
    password(name: 'PASSWD', defaultValue: '', description: 'Please Enter your Gitlab password')
   }
 stages {
  stage('Checkout')
  {
    agent { label 'demo' }
    steps { 
     git branch: 'main', credentialsId: 'GithubCred', url: 'https://github.com/thousif123981/Sample-Java-App.git'
    }
  }

  stage('PreCheck')
  {
   agent { label 'demo' }
//   when { 
//      anyOf {
//           changeset "samplejar/**"
//           changeset "samplewar/**"
//      }
//   }
   steps {
       script {
          env.BUILDME = "yes" 
       }
   }
  }
  stage('Build')
  {
    when {environment name: 'BUILDME', value: 'yes'}
    agent { label 'demo' }
    steps { 
        script {
	    if (params.CLEANBUILD) {
		  cleanstr = "clean"
	    } else {
		  cleanstr = ""
	    }
	
            echo "Building Jar Component ..."
	    dir ("./samplejar") {
	      sh "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64; mvn ${cleanstr} package"
	    }

            echo "Building War Component ..."
	    dir ("./samplewar") {
             sh "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64; mvn ${cleanstr} package"
	    }
	 }
    }
   }
   stage('Code Coverage')
   {
       agent { label 'demo' }
       when {
           environment name: 'BUILDME', value: 'yes'
       }
       steps {
           echo "Running Code Coverage ..."
           dir ("./samplejar") {
               sh "mvn org.jacoco:jacoco-maven-plugin:0.5.5.201112152213:prepare-agent"
           }
       }
   }
   stage('stage artifacts') {
       agent { label 'demo' }
        when {
           environment name: 'BUILDME', value: 'yes'
       }
       environment {
           AWS_REGION = 'ap-south-1'
           S3_BUCKET = 'my-artifacts-storage'
       }
       steps {
           withAWS(credentials: 'AWSCred', region: "${AWS_REGION}") {
               echo "uploading artifacts..."
               s3Upload(file: 'samplewar/target/samplewar.war', bucket: "${S3_BUCKET}", path: 'maven-artifacts/samplewar.war')
           }
       }
   }
   stage('Build Image') {
       agent { label 'demo' }
       when {
           environment name: 'BUILDME', value: 'yes'
       }
       steps {
           script {
               // Prepare the Tag name for the Image
               AppTag = params.APPREPO + ":" + env.BUILD_ID
               BaseTag = params.BASEREPO
               // Docker login needs https appended
               ECR = "https://" + params.ECRURL
               docker.withRegistry(ECR, 'ecr:ap-south-1:AWSCred') {
                   /* Build Docker Image locally */
                         myImage = docker.build(AppTag, "--build-arg BASEIMAGE=${BaseTag} .")
                     /* Push the Image to the Registry */
                         myImage.push()
               }
           }
       }
   }
   stage('Smoke Deploy') {
       agent {label 'demo'}
       when {
           environment name: 'BUILDME', value: 'yes'
       }
       steps {
           script {
               env.DEPLOYIMAGE = params.APPREPO + ":" + env.BUILD_ID
            // Create Containers using the recent Build Image
            sh ("export DEPLOYIMAGE=${DEPLOYIMAGE}; docker-compose up -d")
           }
       }
   }
   stage('Smoke Test') {
       agent {label 'demo'}
       when {
           environment name:'BUILDME', value: 'yes'
       }
       steps {
           catchError(buildResult: 'SUCCESS', message: 'TEST-CASES FAILED', stageResult: 'UNSTABLE')
           {
               sh "sleep 10; chmod +x runsmokes.sh; ./runsmokes.sh"
           }
       }
   post {
       always {
           script {
               env.DEPLOYIMAGE = params.APPREPO + ":" + env.BUILD_ID
                // Create Containers using the recent Build Image
                sh ("export DEPLOYIMAGE=${DEPLOYIMAGE}; docker-compose down")
                sh ("docker rmi ${params.APPREPO}:${env.BUILD_ID}")
           }
       }
   }
   }
   stage('Trigger CD') {
       agent {label 'demo'}
       when {
           environment name: 'BUILDME', value: 'yes'
       }
       steps {
           script {
               TAG = '\\/' + params.APPREPO + ":" + env.BUILD_ID
               build job: 'Deployment_Pipeline', parameters: [string(name: 'IMAGE', value: TAG), password(name: 'PASSWD', value: params.PASSWD)]
           }
       }
   }
 }
}
