# My Ansible Learning Journey - DevOps Engineer Transition

## About Me
I'm transitioning into a DevOps Engineer role with 3.5 years of experience and have been practicing Ansible for the past year. This repository showcases my hands-on learning and understanding of configuration management and automation.

---

## Table of Contents
1. [Why Ansible?](#why-ansible)
2. [Configuration Management](#configuration-management)
3. [Variables & Precedence](#variables--precedence)
4. [Inventory Management](#inventory-management)
5. [Playbook Concepts](#playbook-concepts)
6. [Advanced Features](#advanced-features)
7. [Security with Ansible Vault](#security-with-ansible-vault)
8. [Interview Questions](#interview-questions)

---

## Why Ansible?

### The Problem It Solves
Imagine you're managing 100 servers and need to install nginx on all of them. You could:
- SSH into each server manually (takes days, error-prone)
- Write bash scripts (but what about different OS versions?)
- Use Ansible (declarative, idempotent, agentless)

**Real-world scenario**: Your company launches a new feature requiring a configuration change across 50 production servers. Without Ansible, this is a nightmare. With Ansible, it's one command: `ansible-playbook deploy.yaml`

### Why I Chose Ansible Over Others
- **Agentless**: No need to install agents on target machines (unlike Puppet/Chef)
- **YAML-based**: Human-readable, easy to learn
- **Idempotent**: Run it 100 times, same result (safe for production)
- **Push-based**: Control when changes happen (unlike Puppet's pull model)

---

## Configuration Management

### Ansible.cfg - The Control Center
```ini
[defaults]
inventory = ./inventory/myhosts.ini
```

**Why this matters**: Instead of typing `ansible-playbook -i /path/to/inventory playbook.yml` every time, Ansible automatically knows where to find your inventory. It's like setting your home address as default in GPS.

**Real problem solved**: In a team of 5 DevOps engineers, everyone uses the same inventory path. No confusion, no mistakes.

---

## Variables & Precedence

### The Variable Hierarchy Problem

When I started, I made a mistake: I defined the same variable in multiple places and got confused why my playbook used the "wrong" value. Then I learned about **precedence**.

### Precedence Order (Lowest to Highest)
```
1. Inventory file (lowest priority)
2. Group vars
3. Host variable file
4. Playbook vars
5. vars_files
6. Register variable
7. Command line -e option (highest priority)
```

### Real-World Example

**Scenario**: You have a `location` variable:
- Inventory file says: `location="from inventory file"`
- Host vars says: `location="from host_variable"`
- You run: `ansible-playbook -e location="production"`

**Result**: Command line wins! `location="production"`

**Why this design?**: 
- **Defaults in inventory**: Safe fallback values
- **Host-specific in host_vars**: Per-server customization
- **Command-line override**: Emergency changes without editing files

### My Implementation

**Inventory file** (`myhosts.ini`):
```ini
[web:vars]
location="from inventory file"
c="from inventory file"
```
*Use case*: Default values for all web servers

**Host vars** (`server-1.yml`):
```yaml
location: "from host_variable"
b: "from host_variable"
```
*Use case*: Server-1 needs different location (maybe it's in a different datacenter)

**Group vars** (`web.yml`):
```yaml
location: "from group_variable"
a: "from group_variable"
```
*Use case*: All web servers share common configuration

**Playbook vars** (`deploy.yaml`):
```yaml
vars:
  type: httpd
  version: latest
```
*Use case*: Playbook-specific variables that don't change per host

### The Problem This Solves
Without precedence, you'd need separate playbooks for dev/staging/prod. With precedence, one playbook + different variable files = multiple environments.

---

## Inventory Management

### Static vs Dynamic Inventory

### Static Inventory - The Traditional Way

**File**: `myhosts.ini`
```ini
[web]
server-1 ansible_host=172.31.26.107

[backend]
server-2 ansible_host=172.31.17.84
```

**When to use**: 
- Small, stable infrastructure (5-20 servers)
- On-premise servers with fixed IPs
- Development/testing environments

**Problem**: You launch 10 new EC2 instances. Now you manually update inventory? No!

### Dynamic Inventory - The Cloud Way

**File**: `dynamic.aws_ec2.yaml`
```yaml
plugin: amazon.aws.aws_ec2
regions:
  - us-east-1
filters:
  instance-state-name: running 
  tag:Environment: production
hostnames:
  - private-ip-address
```

**Why this is powerful**:
1. **Auto-discovery**: New EC2 instance with tag `Environment: production`? Automatically added!
2. **No manual updates**: Servers scale up/down, inventory updates itself
3. **Tag-based grouping**: Group by environment, application, team

**Real scenario**: Your application auto-scales from 5 to 50 instances during Black Friday. Dynamic inventory handles it automatically.

**Command to use**:
```bash
ansible-inventory -i dynamic.aws_ec2.yaml --graph
```

---

## Playbook Concepts

### 1. Basic Playbook Structure

**File**: `test.yml`

```yaml
- name: install nginx
  become: yes
  hosts: web
  tasks:
    - name: installing nginx
      package:
        name: nginx
        state: present
```

**Breaking it down**:
- `become: yes`: Run as sudo (most installations need root)
- `hosts: web`: Target the web group from inventory
- `package`: Works across RHEL/Ubuntu (smart module)
- `state: present`: Idempotent - installs only if not present

### 2. Register Variables - Capturing Command Output

**Problem**: You run a command and need its output for the next task.

**My solution** (`test.yml`):
```yaml
- name: execute linux command
  command: hostname -f
  register: result
- name: display nginx details
  debug:
    msg: "command output is {{ result.stdout }}"
```

**Real use case**: 
- Check if a service is running before restarting
- Validate configuration before applying
- Get application version for logging

### 3. Handlers - Smart Service Management

**File**: `handler.yml`

**The Problem**: You update nginx config 5 times during playbook execution. Without handlers, nginx restarts 5 times (slow, disruptive).

**The Solution**:
```yaml
tasks:
  - name: installing nginx
    yum:
      name: nginx
      state: present
    notify: start_server
handlers:
  - name: start_server
    service:
      name: nginx
      state: started
```

**How it works**:
1. Task runs and changes something → Handler is "notified"
2. All tasks complete
3. Handler runs ONCE at the end

**Real scenario**: You update 10 config files. Handler ensures service restarts only once after all changes.

### 4. Include Tasks - DRY Principle

**File**: `include.yml`

**Problem**: You install httpd in 5 different playbooks. Copy-paste everywhere? Maintenance nightmare!

**Solution**:
```yaml
tasks:
  - include_tasks: httpd.yml
```

**Benefits**:
- **Reusability**: Write once, use everywhere
- **Maintainability**: Update in one place
- **Organization**: Complex playbooks stay readable

**Real example**: Your company has a standard security hardening process (20 tasks). Include it in every server provisioning playbook.

### 5. Tags - Selective Execution

**File**: `tag.yaml`

**Problem**: Your playbook has 50 tasks. You only want to run the nginx installation. Run all 50 tasks? Waste of time!

**Solution**:
```yaml
tasks:
  - name: install nginx
    yum:
      name: nginx
      state: present
    tags: nginx
  - name: install httpd
    yum:
      name: httpd
      state: present
    tags: httpd
  - name: display httpd details
    debug:
      var: ansible_run_tags
    tags: always
```

**Usage**:
```bash
# Run only nginx tasks
ansible-playbook tag.yaml --tags nginx

# Skip httpd tasks
ansible-playbook tag.yaml --skip-tags httpd

# Always tag runs regardless
ansible-playbook tag.yaml --tags nginx  # 'always' task still runs
```

**Real scenario**: 
- **Development**: Test only the new feature you added
- **Production**: Run only security patches, skip application updates
- **Troubleshooting**: Re-run only the failing task

---

## Advanced Features

### Vars Files - Separation of Concerns

**File**: `sample.yml`

```yaml
- name: install nginx
  vars_files:
    - ../inventory/group_vars/myvault.yml
  tasks:
    - name: display details
      debug:
        var: pass
```

**Why separate files?**:
- **Security**: Sensitive data in separate files (can be encrypted)
- **Environment-specific**: `vars_dev.yml`, `vars_prod.yml`
- **Team collaboration**: Developers edit playbooks, ops edit vars

**Real workflow**:
```
Developer: Writes playbook logic
Ops team: Provides production variables
Security team: Manages vault files
```

---

## Security with Ansible Vault

### The Password Problem

**Scenario**: Your playbook needs database passwords. Where do you store them?
- ❌ Hardcode in playbook (visible in Git)
- ❌ Environment variables (not portable)
- ✅ Ansible Vault (encrypted, version-controlled)

**File**: `myvault.yml` (encrypted)
```
$ANSIBLE_VAULT;1.1;AES256
62396362663130353733626139643765653036626530626539643265626464326261326330323065
...
```

**Commands I use**:
```bash
# Create encrypted file
ansible-vault create myvault.yml

# Edit encrypted file
ansible-vault edit myvault.yml

# Run playbook with vault
ansible-playbook sample.yml --ask-vault-pass

# Use password file (CI/CD)
ansible-playbook sample.yml --vault-password-file ~/.vault_pass
```

**Real implementation**:
1. Store all passwords/API keys in vault
2. Commit encrypted file to Git (safe!)
3. Share vault password via secure channel (1Password, etc.)
4. CI/CD pipeline uses vault password from secrets manager

**Why this matters**: 
- No credentials in Git history
- Audit trail of who accessed secrets
- Rotate passwords without changing playbooks

---

## My Learning Path & Key Takeaways

### What I Learned the Hard Way

1. **Idempotency is not automatic**: Using `command` module breaks idempotency. Use proper modules (yum, service, copy).

2. **Variable precedence confusion**: Spent hours debugging why my variable wasn't changing. Learned precedence the hard way.

3. **Handlers only run on change**: If task doesn't change anything, handler won't trigger. This is by design!

4. **Always use become carefully**: Don't use `become: yes` globally. Apply it per-task for security.

### Best Practices I Follow

1. **Name every task**: Future you will thank present you
2. **Use tags liberally**: Makes testing so much faster
3. **Separate variables from logic**: Playbooks should be environment-agnostic
4. **Test in dev first**: Always. No exceptions.
5. **Use dynamic inventory for cloud**: Static inventory is technical debt

---

## Interview Questions

### Basic Level

**Q1: What is idempotency in Ansible? Why is it important?**
**A**: Idempotency means running the same playbook multiple times produces the same result without side effects. 

*Example*: If nginx is already installed, running the install task again won't reinstall it. This is crucial because:
- Safe to re-run playbooks in production
- No unexpected changes
- Faster execution (skips unchanged tasks)

**Q2: Explain the difference between static and dynamic inventory.**
**A**: 
- **Static**: Manually maintained file with server IPs/hostnames. Good for stable infrastructure.
- **Dynamic**: Auto-generated from cloud providers (AWS, Azure). Updates automatically when instances are added/removed.

*When I use each*: Static for on-premise servers, dynamic for AWS auto-scaling groups.

**Q3: What is the difference between vars and vars_files?**
**A**: 
- `vars`: Define variables directly in playbook (small, playbook-specific)
- `vars_files`: Load variables from external files (large, reusable, environment-specific)

*Real use*: I use vars_files for production passwords (encrypted with vault).

---

### Intermediate Level

**Q4: Explain Ansible variable precedence. Give a scenario where it matters.**
**A**: Variables can be defined in 7 places, with command-line having highest priority.

*Scenario*: I have `environment: dev` in group_vars. During an emergency production fix, I run:
```bash
ansible-playbook deploy.yml -e environment=prod
```
The `-e` flag overrides group_vars, deploying to prod without editing files.

**Q5: What are handlers and when would you use them?**
**A**: Handlers are tasks that run only when notified and only once at the end.

*Use case*: I update 5 nginx config files. Without handlers, nginx restarts 5 times (slow, causes downtime). With handlers, it restarts once after all changes.

**Q6: How do you manage secrets in Ansible?**
**A**: Using Ansible Vault to encrypt sensitive files.

*My workflow*:
1. Create vault: `ansible-vault create secrets.yml`
2. Store passwords, API keys
3. Commit encrypted file to Git
4. Run with: `--ask-vault-pass`

*Production*: Vault password stored in AWS Secrets Manager, retrieved by CI/CD pipeline.

**Q7: Explain the difference between include_tasks and import_tasks.**
**A**: 
- `include_tasks`: Dynamic, evaluated at runtime, can use loops/conditionals
- `import_tasks`: Static, evaluated at parse time, cannot use loops

*When I use include_tasks*: When I need to conditionally include tasks based on OS type.

---

### Advanced Level

**Q8: You have a playbook that takes 30 minutes to run. How would you optimize it?**
**A**: Multiple strategies:
1. **Use tags**: Run only changed sections during testing
2. **Parallel execution**: Increase `forks` in ansible.cfg (default is 5)
3. **Async tasks**: For long-running tasks (software compilation)
4. **Fact caching**: Avoid gathering facts every run
5. **Pipelining**: Reduce SSH connections

*Real example*: I reduced deployment time from 25 min to 8 min by:
- Using tags during development
- Increasing forks to 20
- Disabling fact gathering where not needed

**Q9: How would you implement blue-green deployment using Ansible?**
**A**: 
1. Use dynamic inventory with tags (blue/green)
2. Deploy to green environment
3. Run smoke tests
4. Update load balancer to point to green
5. Keep blue as rollback option

*Playbook structure*:
```yaml
- hosts: tag_Environment_green
  tasks:
    - name: Deploy new version
    - name: Run health checks
    
- hosts: localhost
  tasks:
    - name: Update load balancer
      when: health_check_passed
```

**Q10: How do you handle different OS distributions in a single playbook?**
**A**: Use conditionals with ansible_facts:

```yaml
- name: Install nginx
  yum:
    name: nginx
  when: ansible_os_family == "RedHat"

- name: Install nginx
  apt:
    name: nginx
  when: ansible_os_family == "Debian"
```

*Better approach*: Use `package` module (OS-agnostic) when possible.

**Q11: Explain a situation where you would use register variables.**
**A**: When you need output from one task to make decisions in another.

*Real scenario*: Check if application is running before deployment:
```yaml
- name: Check app status
  command: systemctl is-active myapp
  register: app_status
  ignore_errors: yes

- name: Deploy new version
  copy:
    src: app.jar
  when: app_status.rc == 0  # Only if app is running
```

**Q12: How would you implement rolling updates with Ansible?**
**A**: Use `serial` keyword:

```yaml
- hosts: web
  serial: 2  # Update 2 servers at a time
  tasks:
    - name: Remove from load balancer
    - name: Deploy new version
    - name: Add back to load balancer
```

*Why this matters*: Updating 100 servers simultaneously causes downtime. Rolling updates maintain availability.

---

### Tricky/Scenario-Based Questions

**Q13: Your playbook works in dev but fails in production. How do you troubleshoot?**
**A**: 
1. **Check variables**: `ansible-playbook playbook.yml --check --diff`
2. **Verify inventory**: `ansible-inventory --list`
3. **Test connectivity**: `ansible all -m ping`
4. **Increase verbosity**: `-vvv` flag
5. **Check facts**: `ansible hostname -m setup`

*Common issues*:
- Different OS versions (dev: Ubuntu, prod: RHEL)
- Missing sudo permissions
- Firewall blocking connections
- Variable precedence issues

**Q14: You need to deploy to 1000 servers but Ansible is slow. What do you do?**
**A**: 
1. **Increase forks**: `forks = 50` in ansible.cfg
2. **Use strategy**: `strategy: free` (don't wait for slow hosts)
3. **Disable fact gathering**: `gather_facts: no` if not needed
4. **Use async**: For long-running tasks
5. **Pipelining**: Reduce SSH overhead

*Real numbers*: Default (5 forks) = 3 hours. Optimized (50 forks + strategy free) = 20 minutes.

**Q15: How do you ensure zero-downtime deployment?**
**A**: 
1. **Health checks**: Verify service is healthy before removing from LB
2. **Serial execution**: Update servers in batches
3. **Rollback plan**: Keep previous version ready
4. **Smoke tests**: Automated tests after deployment

*My implementation*:
```yaml
- hosts: web
  serial: "25%"  # 25% of servers at a time
  tasks:
    - name: Remove from LB
    - name: Deploy
    - name: Health check
    - name: Add to LB
      when: health_check_passed
```

**Q16: A task fails on 10 out of 100 servers. How do you handle it?**
**A**: 
1. **Use ignore_errors**: Continue with other servers
2. **Use failed_when**: Define custom failure conditions
3. **Use max_fail_percentage**: Abort if too many failures

```yaml
- hosts: all
  max_fail_percentage: 10  # Abort if >10% fail
  tasks:
    - name: Risky operation
      command: /usr/local/bin/update.sh
      failed_when: false  # Never fail
      register: result
    
    - name: Check result
      fail:
        msg: "Update failed"
      when: "'ERROR' in result.stdout"
```

**Q17: How do you test Ansible playbooks before production?**
**A**: 
1. **Syntax check**: `ansible-playbook --syntax-check`
2. **Dry run**: `ansible-playbook --check`
3. **Diff mode**: `ansible-playbook --check --diff`
4. **Molecule**: Testing framework for Ansible
5. **Staging environment**: Always test in staging first

*My workflow*:
```bash
# 1. Syntax
ansible-playbook playbook.yml --syntax-check

# 2. Dry run in dev
ansible-playbook playbook.yml --check -i dev_inventory

# 3. Apply in dev
ansible-playbook playbook.yml -i dev_inventory

# 4. Apply in staging
ansible-playbook playbook.yml -i staging_inventory

# 5. Apply in prod (with approval)
ansible-playbook playbook.yml -i prod_inventory
```

---

## What's Next in My Learning Journey

1. **Ansible Tower/AWX**: Web UI, RBAC, job scheduling
2. **Ansible Collections**: Modern way to distribute content
3. **Custom modules**: Writing Python modules for specific needs
4. **Integration with CI/CD**: Jenkins, GitLab CI, GitHub Actions
5. **Terraform + Ansible**: Terraform for infrastructure, Ansible for configuration

---

## Repository Structure

```
ansible/
├── ansible.cfg                    # Main configuration
├── documentation                  # Learning notes
├── inventory/
│   ├── myhosts.ini               # Static inventory
│   ├── static_inventory.ini      # Alternative static inventory
│   ├── dynamic.aws_ec2.yaml      # AWS dynamic inventory
│   ├── host_vars/                # Host-specific variables
│   │   ├── server-1.yml
│   │   └── server-2.yml
│   └── group_vars/               # Group-specific variables
│       └── web/
│           ├── web.yml
│           └── myvault.yml       # Encrypted secrets
└── playbooks/
    ├── deploy.yaml               # Variable demonstration
    ├── test.yml                  # Register variables
    ├── handler.yml               # Handler example
    ├── include.yml               # Task inclusion
    ├── tag.yaml                  # Tag usage
    ├── sample.yml                # Vault integration
    └── httpd.yml                 # Reusable tasks
```

---

## Contact & Collaboration

I'm actively seeking DevOps Engineer opportunities where I can apply my Ansible expertise and continue learning. Open to discussing automation strategies, best practices, and real-world DevOps challenges.

**Key Skills**: Ansible, Configuration Management, Infrastructure as Code, AWS, Linux Administration, CI/CD

---

*This README represents my hands-on learning journey. Each concept was learned by breaking things, fixing them, and understanding the "why" behind the solution.*
