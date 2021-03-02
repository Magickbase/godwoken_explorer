Rake::Task["buildhost:clean:keepdeps"].clear_actions
task "buildhost:clean:keepdeps" do
  on build_host do |host|
    execute :mkdir, "-p", build_path
    within build_path do
      execute :find, "-path ./_build -or -path './_build/*' -or -path ./deps -or -path './deps/*' -or -path ./assets -or -path ./assets/node_modules -or -path './assets/node_modules/*' -or -delete"
    end
  end
end

# replace with ls-remote to gather rev
Rake::Task["local:gather-rev"].clear_actions
task "local:gather-rev" do
  on build_host do |host|
    within repo_path do
      rev = capture(:git, 'ls-remote', fetch(:repo_url), "refs/heads/#{fetch(:branch)}").split(" ").first
      set :rev, rev
      execute :echo, rev
    end
  end
end

task 'buildhost:prepare' do
  on build_host do |host|
    execute :ln, "-sfT #{shared_path}/config/#{mix_env}.secret.exs #{build_path}/config/#{mix_env}.secret.exs"
  end
end
before 'buildhost:mix:deps.get', 'buildhost:prepare'

Rake::Task["buildhost:mix:release"].clear_actions
task "buildhost:mix:release" do
  on build_host do |host|
    within build_path do
      with mix_env: mix_env do
        execute :mix, "distillery.release", "--env=#{distillery_environment}", "--name=#{fetch(:distillery_release)}"
      end
    end
  end
end

task "buildhost:mix:release:upgrade" do
  on build_host do |host|
    within build_path do
      with mix_env: mix_env do
        execute :mix, "distillery.release", "--upgrade", "--env=#{distillery_environment}", "--name=#{fetch(:distillery_release)}"
      end
    end
  end
end

Rake::Task["buildhost:gather-vsn"].clear_actions
task "buildhost:gather-vsn" do
  on build_host do |host|
    within build_path do
      with mix_env: mix_env do
        # Stdout is notoriously polluted, hence we write to a temporary file instead.
        tempfile = capture(:mktemp)

        # Pull the version out of rel/config.exs
        arg =
          %Q{File.write(#{tempfile.inspect}, Distillery.Releases.Config.read!("rel/config.exs").releases[:#{fetch(:distillery_release)}].version)}.shellescape

        execute :mix, "run", "--no-start", "-e", arg
        vsn = capture(:cat, tempfile)

        execute :rm, tempfile

        if vsn.empty?
          raise "unable to determine version for release :#{fetch(:distillery_release)} from rel/config.exs"
        end

        set :vsn, vsn
      end
    end
  end
end
