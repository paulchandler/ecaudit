#!/bin/bash
#
# Copyright 2019 Telefonaktiebolaget LM Ericsson
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

shopt -s extglob

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
CCM_CONFIG=${CCM_CONFIG_DIR:=~/.ccm}

if [ ! -f ${CCM_CONFIG}/CURRENT ]; then
 echo "Unable to find an active ccm cluster"
 exit 2
fi

CCM_CLUSTER_NAME=`cat ${CCM_CONFIG}/CURRENT`
echo "Enabling 4.0 Audit with Chronicle backend into ${CCM_CLUSTER_NAME}"

CLUSTER_PATH=${CCM_CONFIG}/${CCM_CLUSTER_NAME}

update_cache_times() {
 sed -i "s/^$1_validity_in_ms:.*/$1_validity_in_ms: 10000/" $2
 sed -i "/^$1_update_interval_in_ms/d" $2
 sed -i "/^$1_validity_in_ms:.*/a\
$1_update_interval_in_ms: 2000" $2
}

enable_audit() {
 mkdir -p $2
 sed -i '/^audit_logging_options/,/^[a-z]/{/^ /d}' $1
 sed -i '/^audit_logging_options/a\  enabled: true' $1
 sed -i '/^audit_logging_options/a\  logger: BinAuditLogger' $1
 sed -i "/^audit_logging_options/a\  audit_logs_dir: $2" $1
 sed -i '/^audit_logging_options/a\  roll_cycle: MINUTELY' $1
 sed -i '/^audit_logging_options/a\  block: false' $1
 sed -i '/^audit_logging_options/a\  max_log_size: 1073741824 # 1GB' $1
}

for NODE_PATH in ${CLUSTER_PATH}/node*;
do
 sed -i 's/^authenticator:.*/authenticator: PasswordAuthenticator/' ${NODE_PATH}/conf/cassandra.yaml
 sed -i 's/^authorizer:.*/authorizer: CassandraAuthorizer/' ${NODE_PATH}/conf/cassandra.yaml
 sed -i 's/^role_manager:.*/role_manager: CassandraRoleManager/' ${NODE_PATH}/conf/cassandra.yaml
 update_cache_times roles ${NODE_PATH}/conf/cassandra.yaml
 update_cache_times permissions ${NODE_PATH}/conf/cassandra.yaml
 update_cache_times credentials ${NODE_PATH}/conf/cassandra.yaml
 enable_audit ${NODE_PATH}/conf/cassandra.yaml ${NODE_PATH}/logs/audit
done
