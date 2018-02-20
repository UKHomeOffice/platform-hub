require 'rails_helper'

describe ProjectLookupCacheService, type: :service do

  subject { ProjectLookupCacheService.new }

  let!(:project_1) { create :project, shortname: 'FOO' }
  let!(:project_2) { create :project, shortname: 'bar' }
  let!(:project_3) { create :project, shortname: 'bAZ' }

  context 'empty cache' do
    before do
      allow(Project).to receive(:find_by).and_call_original
      allow(Project).to receive(:by_shortname).and_call_original
    end

    context 'non-existent project' do
      it 'should lookup from the database and return nil' do
        expect(subject.by_id('does-not-exist')).to be nil
        expect(Project).to have_received(:find_by)
      end

      it 'should lookup from the database and return nil' do
        expect(subject.by_shortname('does-not-exist')).to be nil
        expect(Project).to have_received(:by_shortname)
      end
    end

    context 'existing project by ID' do
      it 'should lookup from the database and return the project' do
        expect(subject.by_id(project_1.id)).to eq project_1
        expect(Project).to have_received(:find_by)
      end
    end

    context 'existing project by shortname' do
      it 'should lookup from the database and return the project' do
        expect(subject.by_shortname('foo')).to eq project_1
        expect(Project).to have_received(:by_shortname)
      end

      it 'should lookup from the database and return the project' do
        expect(subject.by_shortname('BAR')).to eq project_2
        expect(Project).to have_received(:by_shortname)
      end
    end
  end

  context 'some items populated in cache' do
    before do
      subject.by_id(project_3.id)
      subject.by_shortname('fOo')

      # Only spy after we've done the above
      allow(Project).to receive(:find_by).and_call_original
      allow(Project).to receive(:by_shortname).and_call_original
    end

    context 'non-existent project' do
      it 'should lookup from the database and return nil' do
        expect(subject.by_shortname('does-not-exist')).to be nil
        expect(Project).to have_received(:by_shortname)
      end
    end

    context 'existing projects' do
      context 'cache miss' do
        it 'should lookup from the database and return the project' do
          expect(subject.by_id(project_2.id)).to eq project_2
          expect(Project).to have_received(:find_by)
        end

        it 'should lookup from the database and return the project' do
          expect(subject.by_shortname('Bar')).to eq project_2
          expect(Project).to have_received(:by_shortname)
        end
      end

      context 'cache hit by ID' do
        it 'should not lookup from the database and return the project' do
          expect(subject.by_id(project_3.id)).to eq project_3
          expect(Project).not_to have_received(:find_by)
        end

        it 'should not lookup from the database and return the project' do
          expect(subject.by_id(project_1.id)).to eq project_1
          expect(Project).not_to have_received(:find_by)
        end
      end

      context 'cache hit by shortname' do
        it 'should not lookup from the database and return the project' do
          expect(subject.by_shortname('BAZ')).to eq project_3
          expect(Project).not_to have_received(:by_shortname)
        end

        it 'should not lookup from the database and return the project' do
          expect(subject.by_shortname('foo')).to eq project_1
          expect(Project).not_to have_received(:by_shortname)
        end
      end

      it 'should return the exact same instance from the cache' do
        a = subject.by_id(project_1.id)
        b = subject.by_shortname('FOO')
        expect(a).to be b

        a = subject.by_shortname('foo')
        b = subject.by_shortname('FOO')
        expect(a).to be b

        expect(Project).not_to have_received(:find_by)
        expect(Project).not_to have_received(:by_shortname)
      end
    end
  end

end
