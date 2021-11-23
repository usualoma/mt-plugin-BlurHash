use ExtUtils::MakeMaker;
use YAML;

my $config = YAML::LoadFile((glob('./plugins/*/config.yaml'))[0]);

WriteMakefile(
    NAME     => $config->{name},
    VERSION  => $config->{version},
    SKIP     => [qw(distdir)],
    DISTNAME => $config->{name},
);

sub MY::top_targets {
    << 'Makefile';
npm-install:
	cd ./mt-static/plugins/* && npm ci

npm-build:
	cd ./mt-static/plugins/* && npm run build

build: npm-install npm-build

create_distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \
		-e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"
	perl -MYAML -e 'my $$f = "$(DISTVNAME)/plugins/$(NAME)/config.yaml"; my $$c = YAML::LoadFile($$f); if ($$c->{version} ne "$(VERSION)") { $$c->{version} = "$(VERSION)"; YAML::DumpFile($$f, $$c) }'

distdir : create_distdir build
	$(NOECHO) $(NOOP)

manifest : build

Makefile
}
