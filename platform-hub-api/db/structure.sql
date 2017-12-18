--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.1
-- Dumped by pg_dump version 9.6.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: allocations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE allocations (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    allocatable_type character varying NOT NULL,
    allocatable_id uuid NOT NULL,
    allocation_receivable_type character varying NOT NULL,
    allocation_receivable_id uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: announcement_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE announcement_templates (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    shortname character varying NOT NULL,
    slug character varying NOT NULL,
    description text,
    spec json NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: announcements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE announcements (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    level character varying NOT NULL,
    title character varying,
    text text,
    is_global boolean DEFAULT false NOT NULL,
    is_sticky boolean DEFAULT false NOT NULL,
    deliver_to json NOT NULL,
    publish_at timestamp without time zone NOT NULL,
    status character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    original_template_id uuid,
    template_definitions json,
    template_data json
);


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: audits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE audits (
    id integer NOT NULL,
    auditable_type character varying,
    auditable_id uuid,
    auditable_descriptor character varying,
    associated_type character varying,
    associated_id uuid,
    associated_descriptor character varying,
    user_id uuid,
    user_name character varying,
    user_email character varying,
    action character varying,
    comment character varying,
    remote_ip character varying,
    request_uuid character varying,
    data json,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: audits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE audits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE audits_id_seq OWNED BY audits.id;


--
-- Name: contact_lists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE contact_lists (
    id character varying NOT NULL,
    email_addresses character varying[],
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: costs_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE costs_reports (
    id character varying NOT NULL,
    year integer NOT NULL,
    month character varying NOT NULL,
    billing_file character varying NOT NULL,
    metrics_file character varying NOT NULL,
    notes text,
    config json NOT NULL,
    results json NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    handler text NOT NULL,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying,
    queue character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE delayed_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE delayed_jobs_id_seq OWNED BY delayed_jobs.id;


--
-- Name: hash_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE hash_records (
    id character varying NOT NULL,
    scope character varying NOT NULL,
    data json NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: identities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE identities (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    provider character varying NOT NULL,
    external_id character varying NOT NULL,
    external_username character varying,
    external_name character varying,
    external_email character varying,
    data json,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: kubernetes_clusters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE kubernetes_clusters (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    description text NOT NULL,
    s3_region character varying NOT NULL,
    s3_bucket_name character varying NOT NULL,
    s3_access_key_id character varying NOT NULL,
    s3_secret_access_key character varying NOT NULL,
    s3_object_key character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    aws_account_id bigint
);


--
-- Name: kubernetes_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE kubernetes_groups (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    kind character varying NOT NULL,
    target character varying NOT NULL,
    description text NOT NULL,
    is_privileged boolean DEFAULT false,
    restricted_to_clusters character varying[],
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: kubernetes_namespaces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE kubernetes_namespaces (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    service_id uuid NOT NULL,
    cluster_id uuid NOT NULL,
    name character varying NOT NULL,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: kubernetes_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE kubernetes_tokens (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    tokenable_type character varying NOT NULL,
    tokenable_id uuid NOT NULL,
    cluster_id uuid NOT NULL,
    kind character varying NOT NULL,
    token character varying NOT NULL,
    name character varying NOT NULL,
    uid character varying NOT NULL,
    groups character varying[] DEFAULT '{}'::character varying[],
    description text,
    expire_privileged_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    project_id uuid NOT NULL
);


--
-- Name: platform_themes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE platform_themes (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    title character varying NOT NULL,
    slug character varying NOT NULL,
    description text NOT NULL,
    image_url character varying NOT NULL,
    colour character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    resources json
);


--
-- Name: project_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE project_memberships (
    project_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE projects (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    shortname character varying NOT NULL,
    slug character varying NOT NULL,
    name character varying NOT NULL,
    description text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    cost_centre_code character varying
);


--
-- Name: read_marks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE read_marks (
    id integer NOT NULL,
    readable_type character varying NOT NULL,
    readable_id uuid,
    reader_type character varying NOT NULL,
    reader_id uuid,
    "timestamp" timestamp without time zone
);


--
-- Name: read_marks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE read_marks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: read_marks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE read_marks_id_seq OWNED BY read_marks.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE services (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    description text NOT NULL,
    project_id uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: support_request_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE support_request_templates (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    shortname character varying NOT NULL,
    slug character varying NOT NULL,
    git_hub_repo character varying NOT NULL,
    title character varying NOT NULL,
    description text NOT NULL,
    form_spec json NOT NULL,
    git_hub_issue_spec json NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_scope character varying
);


--
-- Name: user_flags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_flags (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    completed_hub_onboarding boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    completed_services_onboarding boolean DEFAULT false,
    agreed_to_terms_of_service boolean DEFAULT false
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    name character varying NOT NULL,
    email character varying NOT NULL,
    last_seen_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    role character varying,
    is_managerial boolean DEFAULT true,
    is_technical boolean DEFAULT true,
    is_active boolean DEFAULT true
);


--
-- Name: audits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY audits ALTER COLUMN id SET DEFAULT nextval('audits_id_seq'::regclass);


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_jobs ALTER COLUMN id SET DEFAULT nextval('delayed_jobs_id_seq'::regclass);


--
-- Name: read_marks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY read_marks ALTER COLUMN id SET DEFAULT nextval('read_marks_id_seq'::regclass);


--
-- Name: allocations allocations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY allocations
    ADD CONSTRAINT allocations_pkey PRIMARY KEY (id);


--
-- Name: announcement_templates announcement_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY announcement_templates
    ADD CONSTRAINT announcement_templates_pkey PRIMARY KEY (id);


--
-- Name: announcements announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY announcements
    ADD CONSTRAINT announcements_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: audits audits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY audits
    ADD CONSTRAINT audits_pkey PRIMARY KEY (id);


--
-- Name: contact_lists contact_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contact_lists
    ADD CONSTRAINT contact_lists_pkey PRIMARY KEY (id);


--
-- Name: costs_reports costs_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY costs_reports
    ADD CONSTRAINT costs_reports_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: hash_records hash_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY hash_records
    ADD CONSTRAINT hash_records_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: kubernetes_clusters kubernetes_clusters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY kubernetes_clusters
    ADD CONSTRAINT kubernetes_clusters_pkey PRIMARY KEY (id);


--
-- Name: kubernetes_groups kubernetes_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY kubernetes_groups
    ADD CONSTRAINT kubernetes_groups_pkey PRIMARY KEY (id);


--
-- Name: kubernetes_namespaces kubernetes_namespaces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY kubernetes_namespaces
    ADD CONSTRAINT kubernetes_namespaces_pkey PRIMARY KEY (id);


--
-- Name: kubernetes_tokens kubernetes_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY kubernetes_tokens
    ADD CONSTRAINT kubernetes_tokens_pkey PRIMARY KEY (id);


--
-- Name: platform_themes platform_themes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY platform_themes
    ADD CONSTRAINT platform_themes_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: read_marks read_marks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY read_marks
    ADD CONSTRAINT read_marks_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: support_request_templates support_request_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY support_request_templates
    ADD CONSTRAINT support_request_templates_pkey PRIMARY KEY (id);


--
-- Name: users user_email; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT user_email UNIQUE (email);


--
-- Name: user_flags user_flags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_flags
    ADD CONSTRAINT user_flags_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX delayed_jobs_priority ON delayed_jobs USING btree (priority, run_at);


--
-- Name: index_allocations_on_al_rec_type_and_al_rec_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_allocations_on_al_rec_type_and_al_rec_id ON allocations USING btree (allocation_receivable_type, allocation_receivable_id);


--
-- Name: index_allocations_on_al_type_and_al_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_allocations_on_al_type_and_al_id ON allocations USING btree (allocatable_type, allocatable_id);


--
-- Name: index_announcement_templates_on_shortname; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_announcement_templates_on_shortname ON announcement_templates USING btree (shortname);


--
-- Name: index_announcement_templates_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_announcement_templates_on_slug ON announcement_templates USING btree (slug);


--
-- Name: index_announcements_on_is_global; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_announcements_on_is_global ON announcements USING btree (is_global);


--
-- Name: index_announcements_on_level; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_announcements_on_level ON announcements USING btree (level);


--
-- Name: index_announcements_on_original_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_announcements_on_original_template_id ON announcements USING btree (original_template_id);


--
-- Name: index_announcements_on_publish_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_announcements_on_publish_at ON announcements USING btree (publish_at);


--
-- Name: index_announcements_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_announcements_on_status ON announcements USING btree (status);


--
-- Name: index_audits_on_associated_type_and_associated_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audits_on_associated_type_and_associated_id ON audits USING btree (associated_type, associated_id);


--
-- Name: index_audits_on_auditable_type_and_auditable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audits_on_auditable_type_and_auditable_id ON audits USING btree (auditable_type, auditable_id);


--
-- Name: index_audits_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audits_on_created_at ON audits USING btree (created_at);


--
-- Name: index_audits_on_remote_ip; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audits_on_remote_ip ON audits USING btree (remote_ip);


--
-- Name: index_audits_on_request_uuid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audits_on_request_uuid ON audits USING btree (request_uuid);


--
-- Name: index_audits_on_user_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audits_on_user_email ON audits USING btree (user_email);


--
-- Name: index_audits_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audits_on_user_id ON audits USING btree (user_id);


--
-- Name: index_audits_on_user_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_audits_on_user_name ON audits USING btree (user_name);


--
-- Name: index_delayed_jobs_on_queue; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_delayed_jobs_on_queue ON delayed_jobs USING btree (queue);


--
-- Name: index_hash_records_on_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hash_records_on_scope ON hash_records USING btree (scope);


--
-- Name: index_identities_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_identities_on_user_id ON identities USING btree (user_id);


--
-- Name: index_kubernetes_clusters_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_kubernetes_clusters_on_name ON kubernetes_clusters USING btree (name);


--
-- Name: index_kubernetes_groups_on_is_privileged; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_kubernetes_groups_on_is_privileged ON kubernetes_groups USING btree (is_privileged);


--
-- Name: index_kubernetes_groups_on_kind; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_kubernetes_groups_on_kind ON kubernetes_groups USING btree (kind);


--
-- Name: index_kubernetes_groups_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_kubernetes_groups_on_name ON kubernetes_groups USING btree (name);


--
-- Name: index_kubernetes_groups_on_restricted_to_clusters; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_kubernetes_groups_on_restricted_to_clusters ON kubernetes_groups USING gin (restricted_to_clusters);


--
-- Name: index_kubernetes_groups_on_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_kubernetes_groups_on_target ON kubernetes_groups USING btree (target);


--
-- Name: index_kubernetes_namespaces_on_cluster_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_kubernetes_namespaces_on_cluster_id ON kubernetes_namespaces USING btree (cluster_id);


--
-- Name: index_kubernetes_namespaces_on_service_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_kubernetes_namespaces_on_service_id ON kubernetes_namespaces USING btree (service_id);


--
-- Name: index_kubernetes_tokens_on_cluster_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_kubernetes_tokens_on_cluster_id ON kubernetes_tokens USING btree (cluster_id);


--
-- Name: index_kubernetes_tokens_on_kind; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_kubernetes_tokens_on_kind ON kubernetes_tokens USING btree (kind);


--
-- Name: index_kubernetes_tokens_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_kubernetes_tokens_on_project_id ON kubernetes_tokens USING btree (project_id);


--
-- Name: index_kubernetes_tokens_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_kubernetes_tokens_on_token ON kubernetes_tokens USING btree (token);


--
-- Name: index_kubernetes_tokens_on_tokenable_type_and_tokenable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_kubernetes_tokens_on_tokenable_type_and_tokenable_id ON kubernetes_tokens USING btree (tokenable_type, tokenable_id);


--
-- Name: index_kubernetes_tokens_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_kubernetes_tokens_on_uid ON kubernetes_tokens USING btree (uid);


--
-- Name: index_platform_themes_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_platform_themes_on_slug ON platform_themes USING btree (slug);


--
-- Name: index_platform_themes_on_title; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_platform_themes_on_title ON platform_themes USING btree (title);


--
-- Name: index_project_memberships_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_memberships_on_project_id ON project_memberships USING btree (project_id);


--
-- Name: index_project_memberships_on_project_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_project_memberships_on_project_id_and_user_id ON project_memberships USING btree (project_id, user_id);


--
-- Name: index_project_memberships_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_memberships_on_user_id ON project_memberships USING btree (user_id);


--
-- Name: index_projects_on_shortname; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_projects_on_shortname ON projects USING btree (shortname);


--
-- Name: index_projects_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_projects_on_slug ON projects USING btree (slug);


--
-- Name: index_read_marks_on_readable_type_and_readable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_read_marks_on_readable_type_and_readable_id ON read_marks USING btree (readable_type, readable_id);


--
-- Name: index_read_marks_on_reader_type_and_reader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_read_marks_on_reader_type_and_reader_id ON read_marks USING btree (reader_type, reader_id);


--
-- Name: index_services_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_services_on_project_id ON services USING btree (project_id);


--
-- Name: index_support_request_templates_on_git_hub_repo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_support_request_templates_on_git_hub_repo ON support_request_templates USING btree (git_hub_repo);


--
-- Name: index_support_request_templates_on_shortname; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_support_request_templates_on_shortname ON support_request_templates USING btree (shortname);


--
-- Name: index_support_request_templates_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_support_request_templates_on_slug ON support_request_templates USING btree (slug);


--
-- Name: index_users_on_is_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_is_active ON users USING btree (is_active);


--
-- Name: index_users_on_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_role ON users USING btree (role);


--
-- Name: read_marks_reader_readable_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX read_marks_reader_readable_index ON read_marks USING btree (reader_id, reader_type, readable_type, readable_id);


--
-- Name: users_search_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_search_idx ON users USING gin (name gin_trgm_ops);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20170118143012'),
('20170118150822'),
('20170118151109'),
('20170125153828'),
('20170126161234'),
('20170201101239'),
('20170201102040'),
('20170209100930'),
('20170221134425'),
('20170301114421'),
('20170322132009'),
('20170322143551'),
('20170410142703'),
('20170413124233'),
('20170418140933'),
('20170420134436'),
('20170421083936'),
('20170602101700'),
('20170608154827'),
('20170609140110'),
('20170615152928'),
('20170615160858'),
('20170619125933'),
('20170621140022'),
('20170626134741'),
('20170628103710'),
('20170711131233'),
('20170712132824'),
('20170717165305'),
('20170721125027'),
('20170727103721'),
('20170920154859'),
('20171001181648'),
('20171003130836'),
('20171005115420'),
('20171010111440'),
('20171012110416'),
('20171031164247'),
('20171114100517'),
('20171127115843'),
('20171130163603'),
('20171201113437');


