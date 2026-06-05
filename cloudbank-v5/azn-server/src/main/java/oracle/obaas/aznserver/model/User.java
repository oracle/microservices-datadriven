// Copyright (c) 2023, 2026, Oracle and/or its affiliates.

package oracle.obaas.aznserver.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;

@Entity
@Table(name = "users", schema = "user_repo")
@Data
@AllArgsConstructor
@NoArgsConstructor
@ToString(exclude = {"password", "otp"})
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "USER_ID")
    private Long userId;
    @Column(name = "USERNAME", nullable = false)
    private String username;
    /**
     * Stores the BCrypt hash that is persisted in USER_REPO.USERS.PASSWORD.
     * Cleartext passwords may be accepted at API boundaries, but they must be
     * encoded before this entity is saved.
     */
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    @Column(name = "PASSWORD", nullable = false, length = 255)
    private String password;
    @Column(name = "ROLES", nullable = false)
    private String roles;
    @Column(name = "EMAIL")
    private String email;
    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    @Column(name = "OTP")
    private String otp;

    /**
     * Create a user object.
     * 
     * @param username The username.
     * @param password The encoded password hash for persistence.
     * @param roles    The roles assigned the user, as a comma separated list, e.g.
     *                 "ROLE_USER,ROLE_ADMIN".
     */
    public User(String username, String password, String roles) {
        this.username = username;
        this.password = password;
        this.roles = roles;
    }

    // This constructor should only be used during testing with a mock repository,
    // when we need to set the id manually
    public User(long userId, String username, String password, String roles) {
        this(username, password, roles);
        this.userId = userId;
    }

    /**
     * Create a user object.
     * 
     * @param username The username.
     * @param password The encoded password hash for persistence.
     * @param roles    The roles assigned the user, as a comma separated list, e.g.
     *                 "ROLE_USER,ROLE_ADMIN".
     * @param email    The email associated with user account.
     */
    public User(String username, String password, String roles, String email) {
        this(username, password, roles);
        this.email = email;
    }

}
