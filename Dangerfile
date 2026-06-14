# Dangerfile — ExpenseMy PR automation rules
# Runs via `bundle exec danger` in the Danger GitHub Actions workflow.

# ---------------------------------------------------------------------------
# 1. PR description required
# ---------------------------------------------------------------------------
if github.pr_body.nil? || github.pr_body.strip.empty?
  warn "This PR has no description. Please explain what changed and why."
end

# ---------------------------------------------------------------------------
# 2. CHANGELOG must be updated
# ---------------------------------------------------------------------------
changelog_updated = git.modified_files.include?("CHANGELOG.md") ||
                    git.added_files.include?("CHANGELOG.md")
fail "Please update CHANGELOG.md to document your changes." unless changelog_updated

# ---------------------------------------------------------------------------
# 3. Warn on large Swift files (> 300 lines)
# ---------------------------------------------------------------------------
swift_files = (git.modified_files + git.added_files).select { |f| f.end_with?(".swift") }

swift_files.each do |file|
  next unless File.exist?(file)

  line_count = File.readlines(file).count
  if line_count > 300
    warn "#{file} is #{line_count} lines — consider splitting it into smaller files (recommended max: 300)."
  end
end

# ---------------------------------------------------------------------------
# 4. Warn on large PRs (> 10 files)
# ---------------------------------------------------------------------------
changed_file_count = (git.modified_files + git.added_files + git.deleted_files).uniq.count
if changed_file_count > 10
  warn "This PR touches #{changed_file_count} files. Consider splitting it into smaller, focused PRs."
end

# ---------------------------------------------------------------------------
# 5. Test-to-source file ratio message
# ---------------------------------------------------------------------------
all_swift = (git.modified_files + git.added_files).select { |f| f.end_with?(".swift") }
test_files   = all_swift.select { |f| f.include?("Tests/") || f.end_with?("Tests.swift") || f.end_with?("Spec.swift") }
source_files = all_swift - test_files

if source_files.any? || test_files.any?
  message "Test coverage in this PR: **#{test_files.count}** test file(s) vs **#{source_files.count}** source file(s)."
  if source_files.count > 0 && test_files.count == 0
    warn "No test files were modified alongside source changes. Consider adding or updating tests."
  end
end

# ---------------------------------------------------------------------------
# 6. Security: never commit GoogleService-Info.plist
# ---------------------------------------------------------------------------
all_changed = git.modified_files + git.added_files
if all_changed.any? { |f| File.basename(f) == "GoogleService-Info.plist" }
  warn "GoogleService-Info.plist is included in this PR. Make sure it is in .gitignore and does NOT contain production credentials."
end

# ---------------------------------------------------------------------------
# 7. Security: never commit .env files
# ---------------------------------------------------------------------------
if all_changed.any? { |f| File.basename(f).start_with?(".env") || f.end_with?(".env") }
  warn ".env file detected in this PR. Environment files should never be committed — add them to .gitignore."
end

# ---------------------------------------------------------------------------
# 8. Security: never commit code-signing artefacts
# ---------------------------------------------------------------------------
signing_files = all_changed.select { |f| f.end_with?(".p12") || f.end_with?(".mobileprovision") }
if signing_files.any?
  fail "Code-signing file(s) detected in the PR diff: #{signing_files.join(', ')}. " \
       "Remove them immediately — these must never be committed."
end
