module Results
  class Templates
    def self.find(template_name)
      all.find { |template| template.name == template_name }
    end

    def self.all
      [Results::Template.new('Ramble', 'inclusive', 3,
                             ['Overall Men', 'Overall Women', 'Masters Men', 'Masters Women',
                              'Under 20 Men', 'Under 20 Women', '20 to 29 Men', '20 to 29 Women',
                              '30 to 39 Men', '30 to 39 Women', '40 to 49 Men', '40 to 49 Women',
                              '50 to 59 Men', '50 to 59 Women', '60 to 69 Men', '60 to 69 Women']
                                 .map { |name| Results::Categories.find(name) }),
       Results::Template.new('Blue Sky', 'inclusive', 3,
                             ['Overall Men', 'Overall Women', 'Under 40 Men', 'Under 40 Women',
                              'Masters Men', 'Masters Women', 'Grandmasters Men', 'Grandmasters Women']
                                 .map { |name| Results::Categories.find(name) }),
       Results::Template.new('Simple', 'inclusive', 3,
                             ['Overall Men', 'Overall Women']
                                 .map { |name| Results::Categories.find(name) })
      ]
    end
  end
end
