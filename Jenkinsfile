pipeline {
    // agent any

    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: node
      image: node:20-alpine
      command:
        - cat
      tty: true
'''
            defaultContainer 'node'
        }
    }
    // tools {
    //     nodejs 'node26'
    // }

    environment {
        APP_NAME = 'taskflow-api'
        NODE_ENV = 'test'

        AWS_ACCESS_KEY_ID     = 'test'
        AWS_SECRET_ACCESS_KEY = 'test'
        AWS_DEFAULT_REGION    = 'us-east-1'

        AWS_ENDPOINT_URL    = 'http://localstack:4566'
        AWS_ENDPOINT_URL_S3 = 'http://localstack:4566'
    }

    options {
        timeout(time: 20, unit: 'MINUTES')

        parallelsAlwaysFailFast()
    }

    stages {
        // =========================================================
        // Detect CI mode
        // =========================================================

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

                    echo "Hostname:"
                    hostname

                    echo ""

                    echo "Node:"
                    node --version

                    echo ""

                    echo "NPM:"
                    npm --version

                    echo ""

                    echo "Pod environment:"
                    printenv | sort | grep -E \
                        'JENKINS|NODE_NAME|WORKSPACE|HOSTNAME' \
                        || true

                    echo "========================================"
                '''
            }
        }
        // =========================================================
        // FULL CI - Secret Detection
        // =========================================================

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

                    docker run --rm \
                        -v "$WORKSPACE:/repo" \
                        ghcr.io/gitleaks/gitleaks:latest \
                        git /repo \
                        --config=/repo/.gitleaks.toml \
                        --report-format json \
                        --report-path /repo/reports/gitleaks.json \
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

        // =========================================================
        // Install
        // Runs on FAST and FULL
        // =========================================================

        stage('Install') {
            steps {
                dir('backend') {
                    sh 'npm ci'
                }
            }
        }

        // =========================================================
        // FULL CI - SAST
        // =========================================================

        stage('SAST - ESLint Security') {
            when {
                expression {
                    env.CI_MODE == 'FULL'
                }
            }

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

        stage('SAST - Semgrep') {
            when {
                expression {
                    env.CI_MODE == 'FULL'
                }
            }

            steps {
                dir('backend') {
                    sh '''
                        mkdir -p reports

                        docker run --rm \
                            -v "$PWD:/src" \
                            -w /src \
                            semgrep/semgrep:latest \
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

        // =========================================================
        // FULL CI - SCA
        // =========================================================

        stage('SCA - npm audit') {
            when {
                expression {
                    env.CI_MODE == 'FULL'
                }
            }

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
                        }
                        else if (
                            high > 0 ||
                            moderate > 0 ||
                            low > 0
                        ) {
                            unstable(
                                'SCA warning: vulnerabilities found, but no critical vulnerabilities.'
                            )
                        }
                        else {
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

        // =========================================================
        // Resolve Docker image
        // FULL only
        // =========================================================

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

        stage('Build Image') {
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

                        sh """
                            docker build \
                                -t ${env.IMAGE_NAME} \
                                .

                            docker push \
                                ${env.IMAGE_NAME}
                        """
                    }
                }
            }
        }

        // =========================================================
        // FULL CI - Container security
        // =========================================================

        stage('Container Scan') {
            when {
                expression {
                    env.CI_MODE == 'FULL'
                }
            }

            steps {
                dir('backend') {
                    sh """
                        mkdir -p reports

                        echo "===== Trivy Vulnerability Report ====="

                        docker run --rm \
                            --network host \
                            aquasec/trivy:latest \
                            image \
                            --insecure \
                            --severity HIGH,CRITICAL \
                            --format table \
                            ${env.IMAGE_NAME}

                        docker run --rm \
                            --network host \
                            -v "\$PWD/reports:/reports" \
                            aquasec/trivy:latest \
                            image \
                            --insecure \
                            --exit-code 1 \
                            --severity HIGH,CRITICAL \
                            --format sarif \
                            --output /reports/trivy-image.sarif \
                            ${env.IMAGE_NAME}
                    """
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

        // =========================================================
        // MAIN ONLY - SBOM
        // =========================================================

        stage('Generate SBOM') {
            when {
                branch 'main'
            }

            steps {
                dir('backend') {
                    sh """
                        mkdir -p reports

                        docker run --rm \
                            -v /var/run/docker.sock:/var/run/docker.sock \
                            -v "\$PWD/reports:/reports" \
                            anchore/syft:latest \
                            docker:${env.IMAGE_NAME} \
                            -o cyclonedx-json=/reports/taskflow-api.cdx.json
                    """
                }
            }
        }

        stage('Sign SBOM') {
            when {
                branch 'main'
            }

            steps {
                dir('backend') {
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
                        sh '''
                            docker rm \
                                -f cosign-sbom-sign \
                                || true

                            docker create \
                                --name cosign-sbom-sign \
                                --user 0 \
                                -e COSIGN_PASSWORD="$COSIGN_PASSWORD" \
                                ghcr.io/sigstore/cosign/cosign:latest \
                                sign-blob \
                                --yes \
                                --key /tmp/cosign.key \
                                --bundle /tmp/taskflow-api.cdx.sigstore.json \
                                /tmp/taskflow-api.cdx.json

                            docker cp \
                                reports/taskflow-api.cdx.json \
                                cosign-sbom-sign:/tmp/taskflow-api.cdx.json

                            docker cp \
                                "$COSIGN_KEY_FILE" \
                                cosign-sbom-sign:/tmp/cosign.key

                            docker start \
                                -a cosign-sbom-sign

                            docker cp \
                                cosign-sbom-sign:/tmp/taskflow-api.cdx.sigstore.json \
                                reports/taskflow-api.cdx.sigstore.json

                            docker rm \
                                cosign-sbom-sign
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

                    sh '''
                        docker rm \
                            -f cosign-sbom-sign \
                            || true
                    '''
                }
            }
        }

        stage('Verify SBOM Signature') {
            when {
                branch 'main'
            }

            steps {
                dir('backend') {
                    withCredentials([
                        file(
                            credentialsId: 'cosign-public-key',
                            variable: 'COSIGN_PUB_FILE'
                        )
                    ]) {
                        sh '''
                            docker rm \
                                -f cosign-sbom-verify \
                                || true

                            docker create \
                                --name cosign-sbom-verify \
                                --user 0 \
                                ghcr.io/sigstore/cosign/cosign:latest \
                                verify-blob \
                                --key /tmp/cosign.pub \
                                --bundle /tmp/taskflow-api.cdx.sigstore.json \
                                /tmp/taskflow-api.cdx.json

                            docker cp \
                                reports/taskflow-api.cdx.json \
                                cosign-sbom-verify:/tmp/taskflow-api.cdx.json

                            docker cp \
                                reports/taskflow-api.cdx.sigstore.json \
                                cosign-sbom-verify:/tmp/taskflow-api.cdx.sigstore.json

                            docker cp \
                                "$COSIGN_PUB_FILE" \
                                cosign-sbom-verify:/tmp/cosign.pub

                            docker start \
                                -a cosign-sbom-verify

                            docker rm \
                                cosign-sbom-verify
                        '''
                    }
                }
            }

            post {
                always {
                    sh '''
                        docker rm \
                            -f cosign-sbom-verify \
                            || true
                    '''
                }
            }
        }

        // =========================================================
        // FULL CI - OPA
        // =========================================================

        stage('Policy Gate') {
            when {
                expression {
                    env.CI_MODE == 'FULL'
                }
            }

            steps {
                sh '''
                    echo "Policy violations:"

                    docker run --rm \
                        -v "$WORKSPACE:/workspace" \
                        -w /workspace \
                        openpolicyagent/opa:latest \
                        eval \
                        --data policy/security.rego \
                        --input backend/reports/npm-audit.json \
                        --format pretty \
                        'data.security.deny'

                    echo "Evaluating policy gate..."

                    docker run --rm \
                        -v "$WORKSPACE:/workspace" \
                        -w /workspace \
                        openpolicyagent/opa:latest \
                        eval \
                        --fail \
                        --data policy/security.rego \
                        --input backend/reports/npm-audit.json \
                        --format pretty \
                        'data.security.allow'
                '''
            }
        }

        // =========================================================
        // Lint
        // Runs on FAST and FULL
        // =========================================================

        stage('Lint') {
            steps {
                dir('backend') {
                    sh 'npm run lint'
                }
            }
        }

        // =========================================================
        // FEATURE BRANCH FAST TEST
        // =========================================================

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

        // =========================================================
        // FULL UNIT TEST
        // =========================================================

        stage('Unit Test + Coverage') {
            when {
                expression {
                    env.CI_MODE == 'FULL'
                }
            }

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

        // =========================================================
        // IaC Static Validation
        //
        // PR / develop / main = allowed
        // Direct feature branch = skipped
        //
        // Only runs when IaC files changed.
        // =========================================================

        stage('IaC Lint & Validate') {
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

            parallel {
                stage('Terraform Lint & Validate') {
                    steps {
                        sh '''
                            echo "========================================"
                            echo "Terraform Format Check"
                            echo "========================================"

                            terraform \
                                -chdir=terraform \
                                fmt \
                                -check \
                                -recursive

                            echo "========================================"
                            echo "Terraform Init"
                            echo "========================================"

                            terraform \
                                -chdir=terraform \
                                init \
                                -backend=false

                            echo "========================================"
                            echo "Terraform Validate"
                            echo "========================================"

                            terraform \
                                -chdir=terraform \
                                validate
                        '''
                    }
                }

                stage('Ansible Lint') {
                    steps {
                        sh '''
                            echo "========================================"
                            echo "Ansible Lint"
                            echo "========================================"

                            ansible-lint \
                                ansible/playbook.yml
                        '''
                    }
                }
            }
        }

        stage('IaC Security Scan') {
            when {
                allOf {
                    expression {
                        env.CI_MODE == 'FULL'
                    }

                    changeset 'terraform/**'
                }
            }

            parallel {
                stage('tfsec') {
                    steps {
                        sh '''
                            echo "========================================"
                            echo "Terraform Security Scan - tfsec"
                            echo "========================================"

                            tfsec terraform \
                                --no-color
                        '''
                    }
                }

                stage('Checkov') {
                    steps {
                        sh '''
                            echo "========================================"
                            echo "Terraform Security Scan - Checkov"
                            echo "========================================"

                            checkov \
                                --directory terraform \
                                --framework terraform \
                                --skip-check CKV_AWS_8,CKV_AWS_126,CKV_AWS_135,CKV2_AWS_41
                        '''
                    }
                }
            }
        }

        // =========================================================
        // Terraform PLAN
        //
        // No PR infrastructure mutation.
        // develop/main only.
        // =========================================================

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

                archiveArtifacts(
                    artifacts: 'terraform/tfplan,terraform/plan.txt',
                    fingerprint: true
                )
            }
        }

        // =========================================================
        // MAIN ONLY infrastructure mutation
        //
        // This is intentionally NOT run on:
        // feature/*
        // PR
        // develop
        // =========================================================

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

        // =========================================================
        // FULL CI - SonarQube
        // =========================================================

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

        // =========================================================
        // FULL CI - E2E
        // =========================================================

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

        // =========================================================
        // DEVELOP ONLY
        // =========================================================

        stage('Kubernetes Connectivity') {
            when {
                branch 'develop'
            }

            steps {
                sh '''
                    echo "=== Kubernetes context ==="

                    kubectl \
                        config \
                        current-context

                    echo "=== Kubernetes nodes ==="

                    kubectl \
                        get nodes

                    echo "=== Current workloads ==="

                    kubectl \
                        get deployments

                    kubectl \
                        get svc
                '''
            }
        }

        // =========================================================
        // DEVELOP - Blue / Green deployment
        // =========================================================

        stage('Deploy — Staging') {
            when {
                branch 'develop'
            }

            environment {
                FORCE_POST_SWITCH_FAILURE = 'false'
            }

            steps {
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

        // =========================================================
        // MAIN ONLY
        // =========================================================

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

        // =========================================================
        // Optional LAB cleanup
        //
        // main only
        // =========================================================

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
                    string(
                        credentialsId: 'taskflow-ansible-public-key',
                        variable: 'TF_VAR_ssh_public_key'
                    )
                ]) {
                    sh '''
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

    // =============================================================
    // Global Post
    // =============================================================

    // post {
    //     success {
    //         echo """
    //         ${env.APP_NAME} Pipeline completed successfully.

    //         Branch : ${env.BRANCH_NAME}
    //         Mode   : ${env.CI_MODE}
    //         Env    : ${env.NODE_ENV}
    //         """
    //     }

    //     failure {
    //         echo """
    //         ${env.APP_NAME} Pipeline failed.

    //         Branch : ${env.BRANCH_NAME}
    //         Mode   : ${env.CI_MODE}
    //         Stage  : ${env.STAGE_NAME}
    //         """
    //     }

    //     always {
    //         archiveArtifacts(
    //             artifacts: '**/npm-debug.log*',
    //             allowEmptyArchive: true
    //         )

    //         archiveArtifacts(
    //             artifacts: 'backend/reports/**',
    //             allowEmptyArchive: true
    //         )

    //         sh '''
    //             echo "Cleaning dangling Docker images..."

//             docker image prune \
//                 -f \
//                 || true
//         '''
//     }
// }
}
