const { Database } = require("@formidablejs/framework");

/** @param {Database} DB */
exports.up = ({ schema, fn }) => {
	schema.createTable("users", (table) => {
		table.increments("id").primary();
		table.string("name");
		table.string("email").unique();
		table.timestamp("email_verified_at").nullable();

		// Multi-auth provider support
		// auth_provider: 'local', 'oidc', 'ldap'
		table.string("auth_provider").notNullable().defaultTo("local");
		// External provider ID (e.g., OIDC sub claim, LDAP DN/UID)
		table.string("auth_provider_id").nullable();
		// Password is nullable - only required for 'local' auth
		table.string("password").nullable();

		// Unique constraint: same provider + provider_id should not duplicate
		table.unique(["auth_provider", "auth_provider_id"]);

		table.rememberToken();
		table.timestamps(true, true);
	});

	schema.createTable("password_resets", (table) => {
		table.string("email").primary().unique();
		table.string("token");
		table.timestamp("created_at").defaultTo(fn.now());
	});

	schema.createTable("personal_access_tokens", (table) => {
		table.increments("id").primary();
		table.string("tokenable_type");
		table.bigInteger("tokenable_id").index().unsigned();
		table.string("name");
		table.string("abilities").nullable();
		table.text("payload").nullable();
		table.bigInteger("ttl").index().unsigned().nullable();
		table.timestamp("last_used_at").nullable();
		table.timestamps();
	});

	return schema;
};

/** @param {Database} DB */
exports.down = ({ schema }) => {
	schema.dropTable("users");
	schema.dropTable("password_resets");
	schema.dropTable("personal_access_tokens");

	return schema;
};
