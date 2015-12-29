# Ostagram

A sophisticated web application that provides a web interface for neural network-based image processing. This application combines the content of one image with the artistic style of another using convolutional neural networks and the Neural Style Transfer algorithm.

## Overview

Ostagram is a web service that implements the artistic style transfer algorithm. It allows users to create artistic images by applying the style of famous paintings or artistic works to their own photographs.

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url>
cd ostagram
```

### 2. Install Dependencies

```bash
bundle install
```

### 3. Database Setup

```bash
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake db:seed
```

### 4. Configuration

Create a `config/secrets.yml` file with the following structure:

```yaml
token:
  production: your_session_secret_key

workservers:
  server1:
    host: "deploy"
    username: "deploy"
    password: "your_password"
    remote_neural_path: "/home/deploy/neural-style"
    init_params: "-gpu -1 -image_size 100"
    iteration_count: 10
    admin_email: "admin@example.com"

smtp_settings:
  address: 'smtp.gmail.com'
  port: 587
  domain: 'gmail.com'
  user_name: 'your_email@gmail.com'
  password: 'your_app_password'
  authentication: 'plain'
  enable_starttls_auto: true
```

### 5. Start the Application

```bash
bundle exec rails server
```

## Development

### Running Tests

```bash
bundle exec rake test
```

### Background Jobs

Start Redis and Resque workers:

```bash
redis-server
bundle exec rake resque:work
```

## Acknowledgments
- **Implementation Reference**: [jcjohnson/neural-style](https://github.com/jcjohnson/neural-style)

