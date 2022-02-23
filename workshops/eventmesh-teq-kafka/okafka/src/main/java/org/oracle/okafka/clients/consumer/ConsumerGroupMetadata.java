package org.oracle.okafka.clients.consumer;

import java.util.Objects;
import java.util.Optional;

// TODO Suggest create this class in the project because it is important to Spring
public class ConsumerGroupMetadata {
    private final String groupId;
    private final int generationId;
    private final String memberId;
    private final Optional<String> groupInstanceId;

    public ConsumerGroupMetadata(String groupId, int generationId, String memberId, Optional<String> groupInstanceId) {
        this.groupId = (String) Objects.requireNonNull(groupId, "group.id can't be null");
        this.generationId = generationId;
        this.memberId = (String)Objects.requireNonNull(memberId, "member.id can't be null");
        this.groupInstanceId = (Optional)Objects.requireNonNull(groupInstanceId, "group.instance.id can't be null");
    }

    public ConsumerGroupMetadata(String groupId) {
        this(groupId, -1, "", Optional.empty());
    }

    public String groupId() {
        return this.groupId;
    }

    public int generationId() {
        return this.generationId;
    }

    public String memberId() {
        return this.memberId;
    }

    public Optional<String> groupInstanceId() {
        return this.groupInstanceId;
    }

    public String toString() {
        return String.format("GroupMetadata(groupId = %s, generationId = %d, memberId = %s, groupInstanceId = %s)", this.groupId, this.generationId, this.memberId, this.groupInstanceId.orElse(""));
    }

    public boolean equals(Object o) {
        if (this == o) {
            return true;
        } else if (o != null && this.getClass() == o.getClass()) {
            ConsumerGroupMetadata that = (ConsumerGroupMetadata)o;
            return this.generationId == that.generationId && Objects.equals(this.groupId, that.groupId) && Objects.equals(this.memberId, that.memberId) && Objects.equals(this.groupInstanceId, that.groupInstanceId);
        } else {
            return false;
        }
    }

    public int hashCode() {
        return Objects.hash(new Object[]{this.groupId, this.generationId, this.memberId, this.groupInstanceId});
    }
}
