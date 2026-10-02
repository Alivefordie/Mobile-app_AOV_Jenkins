pipeline {
    // agent any

    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod

spec:
  securityContext:
    fsGroup: 1000

  containers:
    - name: ci
      image: jenkins-ci-agent:lab10
      imagePullPolicy: IfNotPresent

      resources:
        requests:
          cpu: "250m"
          memory: "512Mi"
        limits:
          cpu: "1"
          memory: "1536Mi"

      command:
        - cat

      tty: true

      env:
        - name: DOCKER_HOST
          value: tcp://localhost:2375

        - name: DOCKER_TLS_CERTDIR
          value: ""

        - name: TRIVY_CACHE_DIR
          value: /cache/trivy

      volumeMounts:
        - name: trivy-cache
          mountPath: /cache/trivy

    - name: flutter
      image: taskflow-flutter-ci:lab10
      imagePullPolicy: IfNotPresent

      resources:
        requests:
          cpu: "500m"
          memory: "1Gi"
        limits:
          cpu: "2"
          memory: "5Gi"

      command:
        - cat

      tty: true

      env:
        - name: GRADLE_USER_HOME
          value: /cache/gradle

        - name: PUB_CACHE
          value: /cache/pub

      volumeMounts:
        - name: flutter-cache
          mountPath: /cache

    - name: dind
      image: docker:28-dind
      imagePullPolicy: IfNotPresent

      resources:
        requests:
          cpu: "250m"
          memory: "512Mi"
        limits:
          cpu: "1500m"
          memory: "2Gi"

      securityContext:
        privileged: true

      env:
        - name: DOCKER_TLS_CERTDIR
          value: ""

      args:
        - --host=tcp://0.0.0.0:2375
        - --host=unix:///var/run/docker.sock
        - --insecure-registry=registry:5000

      readinessProbe:
        exec:
          command:
            - docker
            - info

        initialDelaySeconds: 3
        periodSeconds: 2
        timeoutSeconds: 2
        failureThreshold: 30

  volumes:
    - name: flutter-cache
      persistentVolumeClaim:
        claimName: flutter-cache

    - name: trivy-cache
      persistentVolumeClaim:
        claimName: trivy-cache
'''

            defaultContainer 'ci'
        }
    }
    // tools {
    //     nodejs 'node26'
    // }

    environment {
        APP_NAME = 'taskflow-api'
        NODE_ENV = 'test'

        PROMETHEUS_URL = 'http://prometheus:9090'

        AWS_DEFAULT_REGION    = 'us-east-1'
        AWS_ENDPOINT_URL      = 'http://localstack:4566'
        AWS_ENDPOINT_URL_S3   = 'http://localstack:4566'
    }

    options {
        timeout(time: 60, unit: 'MINUTES')

        parallelsAlwaysFailFast()
    }

    stages {
        stage('Environment') {
            steps {
                script {
                    def isFeatureBranch =
                        env.BRANCH_NAME ==~ /^feature\/.+/

                    def isCapstoneBranch =
                        env.BRANCH_NAME == 'feature/lab10-capstone'

                    def isPullRequest =
                        env.CHANGE_ID?.trim()

                    if (isFeatureBranch && !isPullRequest && !isCapstoneBranch) {
                        env.CI_MODE = 'FAST'
                    } else {
                        env.CI_MODE = 'FULL'
                    }

                    echo """
                    ========================================
                    Pipeline Environment
                    ========================================
                    APP_NAME      : ${env.APP_NAME}
                    NODE_ENV      : ${env.NODE_ENV}
                    BRANCH_NAME   : ${env.BRANCH_NAME}
                    CHANGE_ID     : ${env.CHANGE_ID ?: '-'}
                    CHANGE_BRANCH : ${env.CHANGE_BRANCH ?: '-'}
                    CHANGE_TARGET : ${env.CHANGE_TARGET ?: '-'}
                    CI_MODE       : ${env.CI_MODE}
                    ========================================
                    """.stripIndent()
                }

                sh '''
                    node --version
                    npm --version
                '''
            }
        }

        stage('Kubernetes Dynamic Agent') {
            when {
                expression {
                    env.BRANCH_NAME ==~ /^feature\/.+/ &&
                    !env.CHANGE_ID?.trim()
                }
            }

            steps {
                sh '''
                    echo "========================================"
                    echo "Kubernetes Dynamic Jenkins Agent"
                    echo "========================================"

                    echo
                    echo "Hostname:"
                    hostname

                    echo
                    echo "===== Runtime ====="

                    java -version
                    node --version
                    npm --version

                    echo
                    echo "===== Docker ====="

                    docker --version
                    docker compose version
                    docker buildx version

                    echo
                    echo "Waiting for Docker daemon..."

                    i=0

                    until docker info >/dev/null 2>&1
                    do
                        i=$((i + 1))

                        if [ "$i" -ge 30 ]; then
                            echo "Docker daemon did not become ready."
                            exit 1
                        fi

                        sleep 2
                    done

                    docker info

                    echo
                    echo "===== Infrastructure ====="

                    terraform version
                    ansible --version
                    ansible-lint --version

                    echo
                    echo "===== Kubernetes ====="

                    kubectl version --client
                    helm version
                    kind version

                    echo
                    echo "===== Security ====="

                    tfsec --version
                    checkov --version

                    echo
                    echo "===== Utilities ====="

                    yq --version
                    git --version
                    curl --version

                    echo
                    echo "========================================"
                    echo "CI agent ready"
                    echo "========================================"
                '''
            }
        }

        stage('Secrets Detection') {
            when {
                expression {
                    env.CI_MODE == 'FULL'
                }
            }

            steps {
                sh '''
                    mkdir -p reports

                    echo "Recent commits:"
                    git log --oneline -5

                    gitleaks git . \
                        --config=.gitleaks.toml \
                        --report-format json \
                        --report-path reports/gitleaks.json \
                        --redact \
                        --verbose
                '''
            }

            post {
                always {
                    archiveArtifacts(
                        artifacts: 'reports/gitleaks.json',
                        allowEmptyArchive: true
                    )
                }
            }
        }

        stage('Install Dependencies') {
            failFast true

            parallel {
                stage('Backend Install') {
                    steps {
                        dir('backend') {
                            sh 'npm ci'
                        }
                    }
                }

                stage('Mobile Install') {
                    steps {
                        container('flutter') {
                            dir('frontend') {
                                sh '''
                                    flutter --version
                                    dart --version
                                    flutter pub get
                                '''
                            }
                        }
                    }
                }
            }
        }

        stage('Quality & Security Gates') {
            when {
                expression {
                    env.CI_MODE == 'FULL'
                }
            }

            failFast true

            parallel {
                // =================================================
                // Lint
                // =================================================

                stage('Lint') {
                    steps {
                        dir('backend') {
                            sh 'npm run lint'
                        }
                    }
                }

                // =================================================
                // Unit Test
                // =================================================

                stage('Unit Test + Coverage') {
                    steps {
                        dir('backend') {
                            sh '''
                                npm test -- \
                                    --coverage \
                                    --reporters=jest-junit
                            '''
                        }
                    }

                    post {
                        always {
                            dir('backend') {
                                junit(
                                    allowEmptyResults: true,
                                    testResults: 'reports/junit.xml'
                                )

                                recordCoverage(
                                    tools: [[
                                        parser: 'COBERTURA',
                                        pattern: 'coverage/cobertura-coverage.xml'
                                    ]]
                                )
                            }
                        }
                    }
                }

                // =================================================
                // SAST
                // =================================================

                stage('SAST') {
                    stages {
                        stage('ESLint Security') {
                            steps {
                                dir('backend') {
                                    sh '''
                                        mkdir -p reports

                                        npx eslint \
                                            --plugin security \
                                            src/ \
                                            --rule 'prettier/prettier: off' \
                                            -f @microsoft/eslint-formatter-sarif \
                                            -o reports/eslint.sarif

                                        npx eslint \
                                            --plugin security \
                                            src/ \
                                            --rule 'prettier/prettier: off'
                                    '''
                                }
                            }

                            post {
                                always {
                                    archiveArtifacts(
                                        artifacts: 'backend/reports/eslint.sarif',
                                        allowEmptyArchive: true
                                    )
                                }
                            }
                        }

                        stage('Semgrep') {
                            steps {
                                dir('backend') {
                                    sh '''
                                        mkdir -p reports

                                        semgrep scan \
                                            --config=p/owasp-top-ten \
                                            --config=p/nodejs \
                                            --sarif \
                                            --output=reports/semgrep.sarif \
                                            .
                                    '''
                                }
                            }

                            post {
                                always {
                                    archiveArtifacts(
                                        artifacts: 'backend/reports/semgrep.sarif',
                                        allowEmptyArchive: true
                                    )
                                }
                            }
                        }
                    }
                }

                // =================================================
                // SCA
                // =================================================

                stage('SCA - npm audit') {
                    steps {
                        dir('backend') {
                            script {
                                sh '''
                                    mkdir -p reports

                                    npm audit \
                                        --audit-level=high \
                                        --json \
                                        > reports/npm-audit.json || true
                                '''

                                def audit =
                                    readJSON file: 'reports/npm-audit.json'

                                def vulnerabilities =
                                    audit.metadata?.vulnerabilities ?: [:]

                                int critical =
                                    (vulnerabilities.critical ?: 0) as int

                                int high =
                                    (vulnerabilities.high ?: 0) as int

                                int moderate =
                                    (vulnerabilities.moderate ?: 0) as int

                                int low =
                                    (vulnerabilities.low ?: 0) as int

                                echo """
                                npm audit summary:

                                Critical: ${critical}
                                High:     ${high}
                                Moderate: ${moderate}
                                Low:      ${low}
                                """.stripIndent()

                                if (critical > 0) {
                                    echo """
                                    SCA detected ${critical} critical vulnerabilities.
                                    Final enforcement will be handled by OPA.
                                    """.stripIndent()
                                } else if (
                                    high > 0 ||
                                    moderate > 0 ||
                                    low > 0
                                ) {
                                    unstable(
                                        'SCA warning: vulnerabilities found, but no critical vulnerabilities.'
                                    )
                                } else {
                                    echo 'SCA passed: no vulnerabilities found.'
                                }
                            }
                        }
                    }

                    post {
                        always {
                            archiveArtifacts(
                                artifacts: 'backend/reports/npm-audit.json',
                                allowEmptyArchive: true
                            )
                        }
                    }
                }
            }
        }

        stage('Policy Gate') {
            when {
                expression {
                    env.CI_MODE == 'FULL'
                }
            }

            steps {
                sh '''
                    echo "Policy violations:"

                    opa eval \
                        --data policy/security.rego \
                        --input backend/reports/npm-audit.json \
                        --format pretty \
                        'data.security.deny'

                    echo "Evaluating policy gate..."

                    opa eval \
                        --fail \
                        --data policy/security.rego \
                        --input backend/reports/npm-audit.json \
                        --format pretty \
                        'data.security.allow'
                '''
            }
        }

        stage('Mobile Quality & Security') {
            failFast true

            parallel {
                stage('Flutter Analyze') {
                    steps {
                        container('flutter') {
                            dir('frontend') {
                                sh '''
                                    echo "========================================"
                                    echo "Flutter Analyze"
                                    echo "========================================"

                                    flutter analyze
                                '''
                            }
                        }
                    }
                }

                stage('Flutter Test + Coverage') {
                    steps {
                        container('flutter') {
                            dir('frontend') {
                                sh '''
                                    echo "========================================"
                                    echo "Flutter Test"
                                    echo "========================================"

                                    flutter test \
                                        --coverage
                                '''
                            }
                        }
                    }

                    post {
                        always {
                            archiveArtifacts(
                                artifacts: 'frontend/coverage/**',
                                allowEmptyArchive: true
                            )
                        }
                    }
                }

                stage('Mobile SCA - OSV Scanner') {
                    steps {
                        dir('frontend') {
                            sh '''
                                echo "========================================"
                                echo "OSV Scanner"
                                echo "========================================"

                                mkdir -p reports

                                osv-scanner scan source \
                                    --recursive \
                                    .
                            '''
                        }
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            when {
                expression {
                    env.CI_MODE == 'FULL'
                }
            }

            steps {
                dir('backend') {
                    withSonarQubeEnv('SonarQube') {
                        sh '''
                            npx @sonar/scan \
                                -Dsonar.projectKey=taskflow-api \
                                -Dsonar.sources=src \
                                -Dsonar.tests=src \
                                -Dsonar.exclusions=**/*.spec.ts \
                                -Dsonar.test.inclusions=**/*.spec.ts \
                                -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
                        '''
                    }
                }
            }
        }

        stage('Quality Gate') {
            when {
                expression {
                    env.CI_MODE == 'FULL'
                }
            }

            steps {
                timeout(
                    time: 5,
                    unit: 'MINUTES'
                ) {
                    waitForQualityGate(
                        abortPipeline: true
                    )
                }
            }
        }

        stage('Resolve Image') {
            when {
                expression {
                    env.CI_MODE == 'FULL'
                }
            }

            steps {
                script {
                    def backendCommit = sh(
                        script: '''
                            git log -1 --format=%H -- backend/
                        ''',
                        returnStdout: true
                    ).trim()

                    env.IMAGE_TAG =
                        backendCommit.take(7)

                    env.IMAGE_NAME =
                        "registry:5000/taskflow-api:${env.IMAGE_TAG}"

                    echo """
                    Current commit : ${env.GIT_COMMIT.take(7)}
                    Backend commit : ${env.IMAGE_TAG}
                    Image          : ${env.IMAGE_NAME}
                    """.stripIndent()
                }
            }
        }

        stage('Verify Image Exists') {
            when {
                expression {
                    env.CI_MODE == 'FULL'
                }
            }

            steps {
                script {
                    def status = sh(
                        script: """
                            curl \
                                -s \
                                -o /dev/null \
                                -w "%{http_code}" \
                                -H 'Accept: application/vnd.oci.image.manifest.v1+json, application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.docker.distribution.manifest.list.v2+json' \
                                http://registry:5000/v2/taskflow-api/manifests/${env.IMAGE_TAG}
                        """,
                        returnStdout: true
                    ).trim()

                    if (status == '200') {
                        env.NEED_IMAGE_BUILD = 'false'

                        echo "Image exists: ${env.IMAGE_NAME}"
                    }
                    else if (status == '404') {
                        env.NEED_IMAGE_BUILD = 'true'

                        echo "Image does not exist: ${env.IMAGE_NAME}"
                        echo 'Image will be rebuilt.'
                    }
                    else {
                        error """
                        Unable to check registry.
                        HTTP status: ${status}
                        """
                    }
                }
            }
        }

        stage('Parallel Builds') {
            failFast true

            parallel {
                // =================================================
                // MOBILE - Debug APK
                // Every branch
                // =================================================

                stage('Mobile - Build Debug APK') {
                    steps {
                        container('flutter') {
                            dir('frontend') {
                                sh '''
                                    echo "========================================"
                                    echo "Build Debug APK"
                                    echo "========================================"

                                    flutter build apk \
                                        --debug
                                '''
                            }
                        }
                    }

                    post {
                        success {
                            archiveArtifacts(
                                artifacts: 'frontend/build/app/outputs/flutter-apk/app-debug.apk',
                                fingerprint: true
                            )
                        }
                    }
                }

                // =================================================
                // BACKEND - Docker Image
                // FULL only
                // =================================================

                stage('Backend - Build Image') {
                    when {
                        allOf {
                            expression {
                                env.CI_MODE == 'FULL'
                            }

                            anyOf {
                                changeset 'backend/**'

                                expression {
                                    env.NEED_IMAGE_BUILD == 'true'
                                }
                            }
                        }
                    }

                    steps {
                        dir('backend') {
                            script {
                                echo "Building image: ${env.IMAGE_NAME}"

                                sh '''
                                    docker build \
                                        -t "$IMAGE_NAME" \
                                        .

                                    docker push \
                                        "$IMAGE_NAME"
                                '''
                            }
                        }
                    }
                }
            }
        }

        stage('Image Verification') {
            failFast true

            parallel {
                stage('Container Scan') {
                    when {
                        expression {
                            env.CI_MODE == 'FULL'
                        }
                    }

                    steps {
                        dir('backend') {
                            sh '''
                                mkdir -p reports

                                echo "========================================"
                                echo "Trivy Cache"
                                echo "========================================"

                                echo "Cache directory: $TRIVY_CACHE_DIR"

                                mkdir -p "$TRIVY_CACHE_DIR"

                                du -sh "$TRIVY_CACHE_DIR" || true

                                echo
                                echo "========================================"
                                echo "Trivy Vulnerability Report"
                                echo "========================================"

                                trivy image \
                                    --cache-backend memory \
                                    --image-src remote \
                                    --insecure \
                                    --severity HIGH,CRITICAL \
                                    --format table \
                                    "$IMAGE_NAME"

                                echo
                                echo "========================================"
                                echo "Generate SARIF"
                                echo "========================================"

                                trivy image \
                                    --cache-backend memory \
                                    --image-src remote \
                                    --insecure \
                                    --exit-code 1 \
                                    --severity HIGH,CRITICAL \
                                    --format sarif \
                                    --output reports/trivy-image.sarif \
                                    "$IMAGE_NAME"

                                echo
                                echo "========================================"
                                echo "Persistent Trivy Cache"
                                echo "========================================"

                                du -sh "$TRIVY_CACHE_DIR" || true
                            '''
                        }
                    }

                    post {
                        always {
                            archiveArtifacts(
                                artifacts: 'backend/reports/trivy-image.sarif',
                                allowEmptyArchive: true
                            )
                        }
                    }
                }

                stage('E2E') {
                    when {
                        expression {
                            env.CI_MODE == 'FULL'
                        }
                    }

                    steps {
                        dir('backend') {
                            script {
                                withEnv([
                                    "API_IMAGE=${env.IMAGE_NAME}"
                                ]) {
                                    sh '''
                                        docker compose \
                                            down \
                                            --remove-orphans \
                                            || true

                                        docker compose \
                                            up \
                                            -d

                                        docker compose \
                                            ps
                                    '''
                                }
                            }

                            script {
                                docker
                                    .image(
                                        'mcr.microsoft.com/playwright:v1.63.0-noble'
                                    )
                                    .inside(
                                        '--network backend_default'
                                    ) {
                                        sh '''
                                            npm ci

                                            BASE_URL=http://api:3000 \
                                                npx playwright test
                                        '''
                                    }
                            }
                        }
                    }

                    post {
                        always {
                            dir('backend') {
                                junit(
                                    allowEmptyResults: true,
                                    testResults: 'reports/e2e-junit.xml'
                                )

                                publishHTML(
                                    target: [
                                        reportDir: 'playwright-report',
                                        reportFiles: 'index.html',
                                        reportName: 'Playwright HTML Report',
                                        keepAll: true,
                                        alwaysLinkToLastBuild: true,
                                        allowMissing: true
                                    ]
                                )

                                archiveArtifacts(
                                    artifacts: 'playwright-report/**',
                                    allowEmptyArchive: true
                                )

                                script {
                                    if (env.IMAGE_NAME?.trim()) {
                                        withEnv([
                                            "API_IMAGE=${env.IMAGE_NAME}"
                                        ]) {
                                            sh '''
                                                docker compose \
                                                    logs api \
                                                    || true

                                                docker compose \
                                                    down \
                                                    --remove-orphans \
                                                    || true
                                            '''
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                stage('SBOM Pipeline') {
                    when {
                        branch 'main'
                    }

                    stages {
                        stage('Generate SBOM') {
                            when {
                                branch 'main'
                            }

                            steps {
                                dir('backend') {
                                    sh '''
                                    mkdir -p reports

                                    SYFT_REGISTRY_INSECURE_USE_HTTP=true \
                                        syft \
                                        "registry:$IMAGE_NAME" \
                                        -o cyclonedx-json=reports/taskflow-api.cdx.json
                                '''
                                }
                            }
                        }

                        stage('Sign SBOM') {
                            when {
                                branch 'main'
                            }

                            steps {
                                withCredentials([
                                file(
                                    credentialsId: 'cosign-private-key',
                                    variable: 'COSIGN_KEY_FILE'
                                ),
                                string(
                                    credentialsId: 'cosign-password',
                                    variable: 'COSIGN_PASSWORD'
                                )
                            ]) {
                                    dir('backend') {
                                        sh '''
                                        set +x

                                        mkdir -p reports

                                        cosign sign-blob \
                                            --yes \
                                            --key "$COSIGN_KEY_FILE" \
                                            --bundle reports/taskflow-api.cdx.sigstore.json \
                                            reports/taskflow-api.cdx.json
                                    '''
                                    }
                            }
                            }

                            post {
                                always {
                                    archiveArtifacts(
                                    artifacts: '''
                                        backend/reports/taskflow-api.cdx.json,
                                        backend/reports/taskflow-api.cdx.sigstore.json
                                    ''',
                                    allowEmptyArchive: true
                                )
                                }
                            }
                        }

                        stage('Verify SBOM Signature') {
                            when {
                                branch 'main'
                            }

                            steps {
                                withCredentials([
                                file(
                                    credentialsId: 'cosign-public-key',
                                    variable: 'COSIGN_PUB_FILE'
                                )
                            ]) {
                                    dir('backend') {
                                        sh '''
                                        cosign verify-blob \
                                            --key "$COSIGN_PUB_FILE" \
                                            --bundle reports/taskflow-api.cdx.sigstore.json \
                                            reports/taskflow-api.cdx.json
                                    '''
                                    }
                            }
                            }
                        }
                    }
                }
            }
        }

        stage('Unit Test - Fast') {
            when {
                expression {
                    env.CI_MODE == 'FAST'
                }
            }

            steps {
                dir('backend') {
                    echo '''
                    ========================================
                    Fast unit tests
                    Coverage disabled for feature branch.
                    ========================================
                    '''

                    sh 'npm test -- --runInBand'
                }
            }
        }

        stage('IaC Verification') {
            when {
                allOf {
                    expression {
                        env.CI_MODE == 'FULL'
                    }

                    anyOf {
                        changeset 'terraform/**'
                        changeset 'ansible/**'
                    }
                }
            }

            failFast true

            parallel {
                stage('Terraform Validate') {
                    when {
                        changeset 'terraform/**'
                    }

                    steps {
                        sh '''
                        terraform -chdir=terraform fmt -check -recursive
                        terraform -chdir=terraform init -backend=false
                        terraform -chdir=terraform validate
                    '''
                    }
                }

                stage('Ansible Lint') {
                    when {
                        changeset 'ansible/**'
                    }

                    steps {
                        sh 'ansible-lint ansible/playbook.yml'
                    }
                }

                stage('tfsec') {
                    when {
                        changeset 'terraform/**'
                    }

                    steps {
                        sh 'tfsec terraform --no-color'
                    }
                }

                stage('Checkov') {
                    when {
                        changeset 'terraform/**'
                    }

                    steps {
                        sh '''
                        checkov \
                            --directory terraform \
                            --framework terraform \
                            --skip-check CKV_AWS_8,CKV_AWS_126,CKV_AWS_135,CKV2_AWS_41
                    '''
                    }
                }
            }
        }

        stage('Terraform Plan') {
            when {
                allOf {
                    anyOf {
                        branch 'develop'
                        branch 'main'
                    }

                    anyOf {
                        changeset 'terraform/**'
                        changeset 'ansible/**'
                    }
                }
            }

            steps {
                withCredentials([
                    string(
                        credentialsId: 'taskflow-ansible-public-key',
                        variable: 'TF_VAR_ssh_public_key'
                    )
                ]) {
                    withEnv([
                        'AWS_EC2_METADATA_DISABLED=true'
                    ]) {
                        sh '''
                        terraform \
                            -chdir=terraform \
                            init \
                            -input=false \
                            -reconfigure

                        terraform \
                            -chdir=terraform \
                            plan \
                            -input=false \
                            -no-color \
                            -out=tfplan

                        terraform \
                            -chdir=terraform \
                            show \
                            -no-color \
                            tfplan \
                            | tee terraform/plan.txt
                    '''
                    }
                }

                archiveArtifacts(
                    artifacts: 'terraform/tfplan,terraform/plan.txt',
                    fingerprint: true
                )
            }
        }

        stage('Infrastructure Approval') {
            when {
                allOf {
                    branch 'main'

                    anyOf {
                        changeset 'terraform/**'
                        changeset 'ansible/**'
                    }
                }
            }

            steps {
                script {
                    def planSummary = sh(
                        script: '''
                            grep \
                                -E '^Plan:|^No changes\\.' \
                                terraform/plan.txt \
                                | tail -1
                        ''',
                        returnStdout: true
                    ).trim()

                    if (!planSummary) {
                        planSummary =
                            'Plan generated. Review terraform/plan.txt artifact.'
                    }

                    timeout(
                        time: 30,
                        unit: 'MINUTES'
                    ) {
                        input(
                            message: """
                            Terraform plan is ready.

                            ${planSummary}

                            Review terraform/plan.txt before approving.

                            Apply this exact Terraform plan?
                            """,
                            ok: 'Approve Apply'
                        )
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when {
                allOf {
                    branch 'main'

                    anyOf {
                        changeset 'terraform/**'
                        changeset 'ansible/**'
                    }
                }
            }

            steps {
                withCredentials([
                    string(
                        credentialsId: 'taskflow-ansible-public-key',
                        variable: 'TF_VAR_ssh_public_key'
                    )
                ]) {
                    sh '''
                        echo "========================================"
                        echo "Terraform Apply"
                        echo "========================================"

                        test -f terraform/tfplan

                        terraform \
                            -chdir=terraform \
                            apply \
                            -input=false \
                            tfplan
                    '''
                }
            }
        }

        stage('Configure with Ansible') {
            when {
                allOf {
                    branch 'main'

                    anyOf {
                        changeset 'terraform/**'
                        changeset 'ansible/**'
                    }
                }
            }

            steps {
                script {
                    def instanceAddress = sh(
                        script: '''
                            terraform \
                                -chdir=terraform \
                                output \
                                -raw instance_address
                        ''',
                        returnStdout: true
                    ).trim()

                    if (!instanceAddress) {
                        error '''
                        Terraform did not return instance_address.
                        '''
                    }

                    echo """
                    Provisioned host:
                    ${instanceAddress}
                    """

                    writeFile(
                        file: 'ansible/inventory.ini',
                        text: """
                        [taskflow]
                        ${instanceAddress}
                        """.stripIndent()
                    )

                    withCredentials([
                        sshUserPrivateKey(
                            credentialsId: 'taskflow-ansible-ssh',
                            keyFileVariable: 'ANSIBLE_SSH_KEY',
                            usernameVariable: 'ANSIBLE_SSH_USER'
                        )
                    ]) {
                        withEnv([
                            "TASKFLOW_IMAGE=${env.IMAGE_NAME}",
                            "INSTANCE_ADDRESS=${instanceAddress}",
                            'ANSIBLE_HOST_KEY_CHECKING=False'
                        ]) {
                            sh '''
                                echo "========================================"
                                echo "Validate Jenkins SSH Key"
                                echo "========================================"

                                ssh-keygen \
                                    -y \
                                    -f "$ANSIBLE_SSH_KEY" \
                                    > /tmp/jenkins-ansible.pub

                                echo "Jenkins public key:"

                                cat \
                                    /tmp/jenkins-ansible.pub

                                echo

                                echo "Jenkins key fingerprint:"

                                ssh-keygen \
                                    -lf \
                                    /tmp/jenkins-ansible.pub

                                echo "========================================"
                                echo "Direct SSH Test"
                                echo "========================================"

                                ssh \
                                    -o StrictHostKeyChecking=no \
                                    -o UserKnownHostsFile=/dev/null \
                                    -o ConnectTimeout=10 \
                                    -i "$ANSIBLE_SSH_KEY" \
                                    "$ANSIBLE_SSH_USER@$INSTANCE_ADDRESS" \
                                    "echo SSH_OK"

                                echo "========================================"
                                echo "Wait for provisioned host"
                                echo "========================================"

                                ansible \
                                    -i ansible/inventory.ini \
                                    taskflow \
                                    -m ansible.builtin.wait_for_connection \
                                    -a "timeout=60" \
                                    --private-key "$ANSIBLE_SSH_KEY" \
                                    -u "$ANSIBLE_SSH_USER"

                                echo "========================================"
                                echo "Configure with Ansible"
                                echo "========================================"

                                ansible-playbook \
                                    -i ansible/inventory.ini \
                                    ansible/playbook.yml \
                                    --private-key "$ANSIBLE_SSH_KEY" \
                                    -u "$ANSIBLE_SSH_USER"
                            '''
                        }
                    }
                }
            }
        }

        stage('Kubernetes Connectivity') {
            when {
                branch 'develop'
            }

            steps {
                withCredentials([
                    file(
                        credentialsId: 'taskflow-kubeconfig',
                        variable: 'KUBE_CONFIG_FILE'
                    )
                ]) {
                    sh '''
                        set +x

                        export KUBECONFIG="$KUBE_CONFIG_FILE"

                        echo "=== Kubernetes context ==="
                        kubectl config current-context

                        echo "=== Kubernetes nodes ==="
                        kubectl get nodes

                        echo "=== Current workloads ==="
                        kubectl get deployments
                        kubectl get svc
                    '''
                }
            }
        }

        stage('Deploy — Staging') {
            when {
                branch 'develop'
            }

            environment {
                FORCE_POST_SWITCH_FAILURE = 'false'
            }

            steps {
                withCredentials([
                    file(
                        credentialsId: 'taskflow-kubeconfig',
                        variable: 'KUBE_CONFIG_FILE'
                    )
                ]) {
                    withEnv([
                        'KUBECONFIG=$KUBE_CONFIG_FILE'
                    ]) {
                        script {
                            def currentColor = sh(
                            script: '''
                                kubectl \
                                    get service \
                                    taskflow-api \
                                    -o jsonpath='{.spec.selector.color}'
                            ''',
                            returnStdout: true
                        ).trim()

                            def nextColor =
                            currentColor == 'blue'
                            ? 'green'
                            : 'blue'

                            env.PREVIOUS_COLOR =
                            currentColor

                            env.NEXT_COLOR =
                            nextColor

                            env.SERVICE_SWITCHED =
                            'false'

                            echo """
                        Current active color : ${currentColor}
                        Deploying to         : ${nextColor}
                        Image                : ${env.IMAGE_NAME}
                        """.stripIndent()

                        // ---------------------------------------------
                        // Deploy inactive color
                        // ---------------------------------------------

                            sh """
                            kubectl \
                                set image \
                                deployment/taskflow-${nextColor} \
                                taskflow-api=${env.IMAGE_NAME}

                            kubectl \
                                rollout status \
                                deployment/taskflow-${nextColor} \
                                --timeout=120s
                        """

                            echo """
                        ${nextColor} rollout completed.
                        """

                        // ---------------------------------------------
                        // Health check inactive deployment
                        // ---------------------------------------------

                            sh """
                            kubectl \
                                port-forward \
                                deployment/taskflow-${nextColor} \
                                18080:3000 \
                                > /tmp/taskflow-port-forward.log \
                                2>&1 &

                            PF_PID=\$!

                            trap \
                                'kill \$PF_PID 2>/dev/null || true' \
                                EXIT

                            sleep 3

                            echo "Checking ${nextColor} health..."

                            curl \
                                --fail \
                                --retry 5 \
                                --retry-delay 2 \
                                http://127.0.0.1:18080/health

                            kill \
                                \$PF_PID \
                                2>/dev/null \
                                || true

                            trap - EXIT
                        """

                            echo """
                        ${nextColor} health check passed.
                        Switching traffic...
                        """

                        // ---------------------------------------------
                        // Switch Service
                        // ---------------------------------------------

                            sh """
                            kubectl \
                                patch service \
                                taskflow-api \
                                --type merge \
                                -p '{"spec":{"selector":{"app":"taskflow-api","color":"${nextColor}"}}}'
                        """

                            env.SERVICE_SWITCHED =
                            'true'

                        // ---------------------------------------------
                        // Post-switch smoke test
                        // ---------------------------------------------

                            sh """
                            echo "Running post-switch smoke test..."

                            kubectl \
                                port-forward \
                                service/taskflow-api \
                                18081:3000 \
                                > /tmp/taskflow-service-port-forward.log \
                                2>&1 &

                            PF_PID=\$!

                            trap \
                                'kill \$PF_PID 2>/dev/null || true' \
                                EXIT

                            sleep 3

                            curl \
                                --fail \
                                --retry 5 \
                                --retry-delay 2 \
                                http://127.0.0.1:18081/health

                            kill \
                                \$PF_PID \
                                2>/dev/null \
                                || true

                            trap - EXIT
                        """

                            echo '''
                        Post-switch smoke test passed.
                        '''

                            if (
                            env.FORCE_POST_SWITCH_FAILURE ==
                            'true'
                        ) {
                                error '''
                            Injected failure after Service switch.
                            '''
                        }

                            def activeColor = sh(
                            script: '''
                                kubectl \
                                    get service \
                                    taskflow-api \
                                    -o jsonpath='{.spec.selector.color}'
                            ''',
                            returnStdout: true
                        ).trim()

                            echo """
                        Service now points to:
                        ${activeColor}
                        """

                            if (activeColor != nextColor) {
                                error '''
                            Service switch verification failed.
                            '''
                            }
                        }
                    }
                }
            }

            post {
                failure {
                    script {
                        if (
                            env.SERVICE_SWITCHED == 'true' &&
                            env.PREVIOUS_COLOR?.trim()
                        ) {
                            echo '''
                            Deployment failed after traffic switch.
                            '''

                            echo """
                            Rolling Service back to:
                            ${env.PREVIOUS_COLOR}
                            """

                            def rollbackStatus = sh(
                                script: """
                                    kubectl \
                                        patch service \
                                        taskflow-api \
                                        --type merge \
                                        -p '{"spec":{"selector":{"app":"taskflow-api","color":"${env.PREVIOUS_COLOR}"}}}'
                                """,
                                returnStatus: true
                            )

                            if (rollbackStatus == 0) {
                                def rollbackColor = sh(
                                    script: '''
                                        kubectl \
                                            get service \
                                            taskflow-api \
                                            -o jsonpath='{.spec.selector.color}'
                                    ''',
                                    returnStdout: true
                                ).trim()

                                if (
                                    rollbackColor ==
                                    env.PREVIOUS_COLOR
                                ) {
                                    echo """
                                    Rollback successful.
                                    Service restored to:
                                    ${rollbackColor}
                                    """
                                }
                                else {
                                    echo """
                                    WARNING:
                                    Rollback command succeeded
                                    but Service points to:
                                    ${rollbackColor}
                                    """
                                }
                            }
                            else {
                                echo '''
                                WARNING:
                                Automatic rollback failed.
                                '''
                            }
                        }
                        else {
                            echo '''
                            Failure occurred before traffic switch.
                            No Service rollback required.
                            '''
                        }
                    }
                }
            }
        }

        stage('Pipeline Health Gate') {
            when {
                branch 'main'
            }

            steps {
                script {
                    echo '''
                    ========================================
                    Pipeline Health Gate
                    Requirement:
                    Last 20 completed builds
                    Success rate >= 90%
                    ========================================
                    '''

                    long endTime =
                        System.currentTimeMillis() / 1000L

                    // 7 days should easily contain 20 lab builds.
                    long startTime =
                        endTime - (7L * 24L * 60L * 60L)

                    sh """
                        curl -fsS --get \
                            '${env.PROMETHEUS_URL}/api/v1/query_range' \
                            --data-urlencode 'query=sum(jenkins_runs_total_total{job="jenkins"})' \
                            --data-urlencode 'start=${startTime}' \
                            --data-urlencode 'end=${endTime}' \
                            --data-urlencode 'step=15s' \
                            -o prometheus-total.json

                        curl -fsS --get \
                            '${env.PROMETHEUS_URL}/api/v1/query_range' \
                            --data-urlencode 'query=sum(jenkins_runs_success_total{job="jenkins"})' \
                            --data-urlencode 'start=${startTime}' \
                            --data-urlencode 'end=${endTime}' \
                            --data-urlencode 'step=15s' \
                            -o prometheus-success.json
                    """

                    def totalResponse =
                        readJSON file: 'prometheus-total.json'

                    def successResponse =
                        readJSON file: 'prometheus-success.json'

                    // -----------------------------------------------------
                    // Validate Prometheus responses
                    // -----------------------------------------------------

                    if (
                        totalResponse.status != 'success' ||
                        successResponse.status != 'success'
                    ) {
                        error '''
                        Pipeline Health Gate failed:
                        Prometheus query was not successful.
                        '''
                    }

                    def totalResults =
                        totalResponse.data?.result ?: []

                    def successResults =
                        successResponse.data?.result ?: []

                    if (
                        totalResults.isEmpty() ||
                        successResults.isEmpty()
                    ) {
                        error '''
                        Pipeline Health Gate failed:
                        Jenkins build metrics were not found in Prometheus.
                        '''
                    }

                    // -----------------------------------------------------
                    // Convert range-query samples into timestamp -> counter
                    // -----------------------------------------------------

                    Map<Long, Double> totalSamples = [:]

                    totalResults[0].values.each { sample ->
                        long timestamp =
                            ((Number) sample[0]).longValue()

                        double value =
                            sample[1].toString().toDouble()

                        totalSamples[timestamp] = value
                    }

                    Map<Long, Double> successSamples = [:]

                    successResults[0].values.each { sample ->
                        long timestamp =
                            ((Number) sample[0]).longValue()

                        double value =
                            sample[1].toString().toDouble()

                        successSamples[timestamp] = value
                    }

                    // -----------------------------------------------------
                    // Reconstruct build completions from counter increases.
                    //
                    // Jenkins metrics are counters:
                    //
                    // total:
                    //   10 -> 11 = one completed build
                    //
                    // success:
                    //   8 -> 9  = that build succeeded
                    //
                    // Counter reset is also handled here.
                    // -----------------------------------------------------

                    def timestamps =
                        totalSamples
                            .keySet()
                            .intersect(successSamples.keySet())
                            .sort()

                    List<Map> buildGroups = []

                    Double previousTotal = null
                    Double previousSuccess = null

                    timestamps.each { timestamp ->
                        double currentTotal =
                            totalSamples[timestamp]

                        double currentSuccess =
                            successSamples[timestamp]

                        if (
                            previousTotal != null &&
                            previousSuccess != null
                        ) {
                            double totalDelta =
                                currentTotal >= previousTotal
                                    ? currentTotal - previousTotal
                                    : currentTotal

                            double successDelta =
                                currentSuccess >= previousSuccess
                                    ? currentSuccess - previousSuccess
                                    : currentSuccess

                            int builds =
                                Math.round(totalDelta) as int

                            int successes =
                                Math.round(successDelta) as int

                            if (builds > 0) {
                                buildGroups << [
                                    timestamp : timestamp,
                                    builds    : builds,
                                    successes : successes
                                ]
                            }
                        }

                        previousTotal = currentTotal
                        previousSuccess = currentSuccess
                    }

                    // -----------------------------------------------------
                    // Walk backwards until exactly the latest 20 builds
                    // -----------------------------------------------------

                    int requiredBuilds = 20
                    int countedBuilds = 0
                    int successfulBuilds = 0

                    for (
                        int i = buildGroups.size() - 1;
                        i >= 0 && countedBuilds < requiredBuilds;
                        i--
                    ) {
                        def group =
                            buildGroups[i]

                        int remaining =
                            requiredBuilds - countedBuilds

                        /*
                        * Normally this is 1 because Jenkins builds take
                        * longer than the Prometheus scrape interval.
                        *
                        * If multiple builds finish between two scrapes
                        * and only part of that group belongs in the
                        * latest 20, Prometheus counters cannot tell us
                        * which individual ones succeeded.
                        */
                        if (group.builds > remaining) {
                            error """
                            Pipeline Health Gate cannot calculate the
                            exact last ${requiredBuilds} builds.

                            ${group.builds} builds completed between two
                            Prometheus samples while only ${remaining}
                            builds were still required.

                            Reduce the Prometheus scrape interval.
                            """.stripIndent()
                        }

                        countedBuilds +=
                            group.builds

                        successfulBuilds +=
                            group.successes
                    }

                    if (countedBuilds < requiredBuilds) {
                        error """
                        Pipeline Health Gate failed:

                        Only ${countedBuilds} completed builds were found.
                        At least ${requiredBuilds} builds are required.
                        """.stripIndent()
                    }

                    double successRate =
                        (
                            successfulBuilds * 100.0
                        ) / requiredBuilds

                    echo """
                    ========================================
                    Pipeline Health
                    ========================================

                    Builds checked : ${requiredBuilds}
                    Successful     : ${successfulBuilds}
                    Failed/other   : ${requiredBuilds - successfulBuilds}
                    Success rate   : ${String.format('%.2f', successRate)}%
                    Required       : 90.00%

                    ========================================
                    """.stripIndent()

                    if (successRate < 90.0) {
                        error """
                        Pipeline Health Gate FAILED.

                        Rolling success rate:
                        ${String.format('%.2f', successRate)}%

                        Required:
                        >= 90%

                        Production deployment aborted.
                        """.stripIndent()
                    }

                    echo '''
                    Pipeline Health Gate PASSED.
                    Production deployment may continue.
                    '''
                }
            }

            post {
                always {
                    archiveArtifacts(
                        artifacts: '''
                            prometheus-total.json,
                            prometheus-success.json
                        ''',
                        allowEmptyArchive: true
                    )
                }
            }
        }

        stage('Deploy — Production') {
            when {
                beforeInput true
                branch 'main'
            }

            input {
                message 'Deploy to production?'
            }

            steps {
                sh '''
                    echo "Deploying to production..."
                '''
            }
        }

        stage('Destroy Approval') {
            when {
                branch 'main'
            }

            steps {
                timeout(
                    time: 10,
                    unit: 'MINUTES'
                ) {
                    input(
                        message: '''
                        End of lab session.

                        Destroy all infrastructure managed by Terraform?

                        This will remove the provisioned
                        Taskflow environment.
                        ''',
                        ok: 'Destroy Environment'
                    )
                }
            }
        }

        stage('Terraform Destroy & Verify') {
            when {
                branch 'main'
            }

            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'taskflow-localstack-aws',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    ),
                    string(
                        credentialsId: 'taskflow-ansible-public-key',
                        variable: 'TF_VAR_ssh_public_key'
                    )
                ]) {
                    withEnv([
                        'AWS_EC2_METADATA_DISABLED=true'
                    ]) {
                        sh '''
                            set +x

                            echo "========================================"
                            echo "Terraform Destroy"
                            echo "========================================"

                            terraform \
                                -chdir=terraform \
                                init \
                                -input=false \
                                -reconfigure

                            terraform \
                                -chdir=terraform \
                                destroy \
                                -input=false \
                                -auto-approve \
                                -no-color \
                                | tee terraform/destroy.txt

                            echo "========================================"
                            echo "Verify Terraform State"
                            echo "========================================"

                            STATE_RESOURCES="$(
                                terraform \
                                    -chdir=terraform \
                                    state list
                            )"

                            if [ -n "$STATE_RESOURCES" ]; then
                                echo "ERROR:"
                                echo "Terraform state still contains resources:"
                                echo "$STATE_RESOURCES"
                                exit 1
                            fi

                            echo "SUCCESS:"
                            echo "Terraform state contains 0 managed resources."

                            echo "========================================"
                            echo "Terraform State"
                            echo "========================================"

                            terraform \
                                -chdir=terraform \
                                show \
                                -no-color
                        '''
                    }
                }
            }

            post {
                always {
                    archiveArtifacts(
                        artifacts: 'terraform/destroy.txt',
                        allowEmptyArchive: true
                    )
                }
            }
        }

        stage('Archive Artifacts') {
            steps {
                echo 'Preparing build artifacts...'
            }

            post {
                success {
                    echo """
                    ${env.APP_NAME} Pipeline completed successfully.

                    Branch : ${env.BRANCH_NAME}
                    Mode   : ${env.CI_MODE}
                    Env    : ${env.NODE_ENV}
                    """
                }

                failure {
                    echo """
                    ${env.APP_NAME} Pipeline failed.

                    Branch : ${env.BRANCH_NAME}
                    Mode   : ${env.CI_MODE}
                    Stage  : ${env.STAGE_NAME}
                    """
                }

                always {
                    archiveArtifacts(artifacts: '**/npm-debug.log*', allowEmptyArchive: true)

                    archiveArtifacts(artifacts: 'backend/reports/**', allowEmptyArchive: true)
                }
            }
        }
    }
}
