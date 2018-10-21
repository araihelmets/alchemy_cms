require 'spec_helper'

shared_examples_for "an essence" do
  let(:element) { Alchemy::Element.new }
  let(:content) { Alchemy::Content.new(name: 'foo') }
  let(:content_description) { {'name' => 'foo'} }

  it "touches the content after update" do
    essence.save
    content.update(essence: essence, essence_type: essence.class.name)
    date = content.updated_at
    content.essence.update(essence.ingredient_column.to_sym => ingredient_value)
    content.reload
    expect(content.updated_at).not_to eq(date)
  end

  it "should have correct partial path" do
    underscored_essence = essence.class.name.demodulize.underscore
    expect(essence.to_partial_path).to eq("alchemy/essences/#{underscored_essence}_view")
  end

  describe '#description' do
    subject { essence.description }

    context 'without element' do
      it { is_expected.to eq({}) }
    end

    context 'with element' do
      before do
        expect(essence).to receive(:element).at_least(:once).and_return(element)
      end

      context 'but without content descriptions' do
        it { is_expected.to eq({}) }
      end

      context 'and content descriptions' do
        before do
          allow(essence).to receive(:content).and_return(content)
        end

        context 'containing the content name' do
          before do
            expect(element).to receive(:content_descriptions).at_least(:once).and_return([content_description])
          end

          it "returns the content description" do
            is_expected.to eq(content_description)
          end
        end

        context 'not containing the content name' do
          before do
            expect(element).to receive(:content_descriptions).at_least(:once).and_return([])
          end

          it { is_expected.to eq({}) }
        end
      end
    end
  end

  describe '#ingredient=' do
    it 'should set the value to ingredient column' do
      essence.ingredient = ingredient_value
      expect(essence.ingredient).to eq ingredient_value
    end
  end

  describe 'validations' do
    context 'without essence description in elements.yml' do
      it 'should return an empty array' do
        allow(essence).to receive(:description).and_return nil
        expect(essence.validations).to eq([])
      end
    end

    context 'without validations defined in essence description in elements.yml' do
      it 'should return an empty array' do
        allow(essence).to receive(:description).and_return({name: 'test', type: 'EssenceText'})
        expect(essence.validations).to eq([])
      end
    end

    describe 'presence' do
      before do
        allow(essence).to receive(:description).and_return({'validate' => ['presence']})
      end

      context 'when the ingredient column is empty' do
        before do
          essence.update(essence.ingredient_column.to_sym => nil)
        end

        it 'should not be valid' do
          expect(essence).to_not be_valid
        end
      end

      context 'when the ingredient column is not nil' do
        before do
          essence.update(essence.ingredient_column.to_sym => ingredient_value)
        end

        it 'should be valid' do
          expect(essence).to be_valid
        end
      end
    end

    describe 'uniqueness' do
      before do
        allow(essence).to receive(:element).and_return(build_stubbed(:element))
        expect(essence).to receive(:description).at_least(:once).and_return({'validate' => ['uniqueness']})
        essence.update(essence.ingredient_column.to_sym => ingredient_value)
      end

      context 'when a duplicate exists' do
        before do
          allow(essence).to receive(:duplicates).and_return([essence.dup])
        end

        it 'should not be valid' do
          expect(essence).to_not be_valid
        end

        context 'when validated essence is not public' do
          before do
            expect(essence).to receive(:public?).and_return(false)
          end

          it 'should be valid' do
            expect(essence).to be_valid
          end
        end
      end

      context 'when no duplicate exists' do
        before do
          expect(essence).to receive(:duplicates).and_return([])
        end

        it 'should be valid' do
          expect(essence).to be_valid
        end
      end
    end

    describe '#acts_as_essence?' do
      it 'should return true' do
        expect(essence.acts_as_essence?).to be_truthy
      end
    end
  end

  context 'delegations' do
    let(:page)    { create(:restricted_page) }
    let(:element) { create(:element, name: 'headline', create_contents_after_create: true, page: page) }
    let(:content) { element.contents.find_by(essence_type: 'Alchemy::EssenceText') }
    let(:essence) { content.essence }

    it "delegates restricted? to page" do
      expect(page.restricted?).to be(true)
      expect(essence.restricted?).to be(true)
    end

    it "delegates trashed? to element" do
      element.update!(position: nil)
      expect(element.trashed?).to be true
      expect(essence.trashed?).to be true
    end

    it "delegates public? to element" do
      element.update!(public: false)
      expect(element.public?).to be false
      expect(essence.public?).to be false
    end
  end

  describe 'essence relations' do
    let(:page)    { create(:restricted_page) }
    let(:element) { create(:element) }

    it "registers itself on page as essence relation" do
      expect(page.respond_to?(essence.class.model_name.route_key)).to be(true)
    end

    it "registers itself on element as essence relation" do
      expect(element.respond_to?(essence.class.model_name.route_key)).to be(true)
    end
  end
end
