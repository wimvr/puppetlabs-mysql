# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'mysql_database' do
  describe 'setup' do
    pp = <<-MANIFEST
        class { 'mysql::server': }
    MANIFEST
    it 'works with no errors' do
      apply_manifest(pp, catch_failures: true)
    end
  end

  describe 'creating database' do
    pp = <<-MANIFEST
        mysql_database { 'spec_db':
          ensure  => present,
          charset => '#{fetch_charset}',
          collate => '#{fetch_charset}_general_ci',
        }
    MANIFEST
    it 'works without errors' do
      apply_manifest(pp, catch_failures: true)
    end

    it 'finds the database #stdout' do
      run_shell("mysql -NBe \"SHOW DATABASES LIKE 'spec_db'\"") do |r|
        expect(r.stdout).to match(%r{^spec_db$})
        expect(r.stderr).to be_empty
      end
    end
  end

  describe 'charset and collate' do
    pp = <<-MANIFEST
        mysql_database { 'spec_latin1':
          charset => 'latin1',
          collate => 'latin1_swedish_ci',
        }
        mysql_database { 'spec_utf8':
          charset => '#{fetch_charset}',
          collate => '#{fetch_charset}_general_ci',
        }
    MANIFEST
    it 'creates two db of different types idempotently' do
      idempotent_apply(pp)
    end

    it 'finds latin1 db #stdout' do
      run_shell("mysql -NBe \"SHOW VARIABLES LIKE '%_database'\" spec_latin1") do |r|
        expect(r.stdout).to match(%r{^character_set_database\tlatin1\ncollation_database\tlatin1_swedish_ci$})
        expect(r.stderr).to be_empty
      end
    end

    it 'finds utf8 db #stdout' do
      run_shell("mysql -NBe \"SHOW VARIABLES LIKE '%_database'\" spec_utf8") do |r|
        expect(r.stdout).to match(%r{^character_set_database\tutf8(mb3)?\ncollation_database\tutf8(mb3)?_general_ci$})
        expect(r.stderr).to be_empty
      end
    end
  end
end
