task "node:archive:dist" => ["buildhost:archive_path"] do
  buildhost_archive_path = fetch(:buildhost_archive_path)
  vsn = fetch(:vsn)

  on build_host do |build_host|
    execute :cp, "#{buildhost_archive_path} #{app_path}"
  end

  on app_hosts do |host|
    within app_path do
      execute :tar, "-xzf", "godwoken_explorer.tar.gz"
    end
  end
end

task "node:migrate" do
  on build_host do |build_host|
    within build_path do
      with mix_env: mix_env do
        execute :mix, "ecto.migrate"
      end
    end
  end
end

task "node:upgrade" => ["buildhost:gather-vsn"] do
  vsn = fetch(:vsn)
  on app_hosts do |host|
    within app_path do
      execute :cp, "godwoken_explorer.tar.gz", "#{app_path}/releases/#{vsn}/"
      execute "bin/godwoken_explorer", "upgrade", vsn
    end
  end
end
