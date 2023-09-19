package com.ericsson.bss.cassandra.ecaudit.entry;

import com.ericsson.bss.cassandra.ecaudit.common.record.AuditOperation;

public class PrepareAuditOperation implements AuditOperation
{
    private final String operationString;

    /**
     * Construct a new audit operation.
     * @param operationString the operation/statement to wrap.
     */
    public PrepareAuditOperation(String operationString)
    {
        this.operationString = "Prepared: " + operationString;
    }

    @Override
    public String getOperationString()
    {
        return operationString;
    }
    @Override
    public String getNakedOperationString()
    {
        return operationString;
    }

}
